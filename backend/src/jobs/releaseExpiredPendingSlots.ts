import { query, getClient } from '../db';
import { devBookings, devSlots } from '../models/bookingStore';

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

export async function releaseExpiredPendingSlots(timeoutHours: number = 2): Promise<number> {
  const cutoffTime = new Date(Date.now() - timeoutHours * 3600 * 1000);

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      // In-memory dev fallback
      let releasedCount = 0;
      for (const booking of devBookings) {
        if (booking.status === 'requested' && new Date(booking.requested_at) < cutoffTime) {
          booking.status = 'cancelled';
          booking.cancellation_reason = 'Owner response timeout (auto-released)';

          const slot = devSlots.find((s) => s.id === booking.slot_id);
          if (slot && slot.status === 'pending') {
            slot.status = 'open';
            slot.updated_at = new Date();
          }
          releasedCount++;
        }
      }
      return releasedCount;
    }
    throw err;
  }

  try {
    await client.query('BEGIN');

    // Find requested bookings older than cutoff
    const expiredRes = await client.query(
      `SELECT b.id AS booking_id, b.slot_id 
       FROM bookings b
       JOIN availability_slots s ON b.slot_id = s.id
       WHERE b.status = 'requested' AND b.requested_at < $1 FOR UPDATE`,
      [cutoffTime]
    );

    for (const row of expiredRes.rows) {
      await client.query(
        `UPDATE bookings 
         SET status = 'cancelled', cancellation_reason = 'Owner response timeout (auto-released)' 
         WHERE id = $1`,
        [row.booking_id]
      );
      await client.query(
        "UPDATE availability_slots SET status = 'open', updated_at = now() WHERE id = $1",
        [row.slot_id]
      );
    }

    await client.query('COMMIT');
    return expiredRes.rows.length;
  } catch (err) {
    if (client) await client.query('ROLLBACK');
    console.error('Error releasing expired pending slots:', err);
    throw err;
  } finally {
    if (client) client.release();
  }
}
