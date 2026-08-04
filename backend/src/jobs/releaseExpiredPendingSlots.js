const db = require('../models/db');

/**
 * Background task to find and release pending slots older than 2 hours.
 * Sweeps the database, cancels expired bookings, and sets slot status back to 'open'.
 */
async function releaseExpiredPendingSlots() {
  const client = await db.getClient();

  try {
    await client.query('BEGIN');

    // 1. Find bookings in 'requested' state that were requested more than 2 hours ago
    const findExpiredQuery = `
      SELECT b.id as booking_id, b.slot_id
      FROM bookings b
      WHERE b.status = 'requested' AND b.requested_at < now() - INTERVAL '2 hours'
      FOR UPDATE
    `;
    const expiredRes = await client.query(findExpiredQuery);

    if (expiredRes.rows.length === 0) {
      await client.query('COMMIT');
      return;
    }

    console.log(`[Cleaner Job] Found ${expiredRes.rows.length} expired pending bookings. Releasing...`);

    const expiredIds = expiredRes.rows.map(r => r.booking_id);
    const expiredSlotIds = expiredRes.rows.map(r => r.slot_id);

    // 2. Mark bookings as cancelled
    const updateBookingsQuery = `
      UPDATE bookings
      SET status = 'cancelled', cancellation_reason = 'Expired - No owner response within 2 hours'
      WHERE id = ANY($1)
    `;
    await client.query(updateBookingsQuery, [expiredIds]);

    // 3. Mark slots back to 'open'
    const updateSlotsQuery = `
      UPDATE availability_slots
      SET status = 'open', updated_at = now()
      WHERE id = ANY($1)
    `;
    await client.query(updateSlotsQuery, [expiredSlotIds]);

    await client.query('COMMIT');
    console.log(`[Cleaner Job] Successfully released slots: ${expiredSlotIds.join(', ')}`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Cleaner Job Error] Failed to auto-release expired pending slots:', error);
  } finally {
    client.release();
  }
}

/**
 * Starts the cleanup scheduler at the specified interval in milliseconds.
 */
function startCleanupJob(intervalMs = 15 * 60 * 1000) { // default 15 minutes
  console.log(`[Cleaner Job] Initialized. Sweeping database every ${intervalMs / 1000 / 60} minutes...`);
  
  // Run once immediately on startup
  releaseExpiredPendingSlots();

  // Schedule intervals
  return setInterval(releaseExpiredPendingSlots, intervalMs);
}

module.exports = {
  releaseExpiredPendingSlots,
  startCleanupJob
};
