import { Request, Response } from 'express';
import { getClient, query } from '../db';
import {
  createBookingSchema,
  respondBookingSchema,
  updateBookingStatusSchema,
  BookingRecord,
} from '../models/booking';
import { AvailabilitySlotRecord } from '../models/availability';
import { devBookings, devSlots } from '../models/bookingStore';
import { devMachines } from './machineController';
import { devUsers } from '../models/userStore';
import {
  notifyBookingRequested,
  notifyBookingConfirmed,
  notifyBookingRejected,
  notifyBookingStatusUpdated,
} from '../services/notificationService';

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

// POST /api/v1/bookings
// Critical transactional endpoint: SELECT ... FOR UPDATE on slot (FR-5.2 / Architecture Sec 3)
export async function createBooking(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const parseResult = createBookingSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid booking data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { slot_id, land_location } = parseResult.data;

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      // Dev in-memory transactional check-and-lock
      const slotIndex = devSlots.findIndex((s) => s.id === slot_id);
      if (slotIndex === -1) {
        res.status(404).json({ error: 'slot_not_found', message: 'Availability slot not found.' });
        return;
      }

      const slot = devSlots[slotIndex];
      if (slot.status !== 'open') {
        res.status(409).json({
          error: 'slot_no_longer_available',
          message: 'මෙම වේලාව දැනටමත් වෙන්කරවා ගෙන ඇත (This slot is no longer available).',
        });
        return;
      }

      // Lock slot to pending
      slot.status = 'pending';
      slot.updated_at = new Date();

      const machine = devMachines.find((m) => m.id === slot.machine_id);
      const owner = machine ? devUsers.find((u) => u.id === machine.owner_id) : undefined;

      const newBooking: BookingRecord = {
        id: `dev-book-${Date.now()}`,
        slot_id,
        farmer_id: req.user.id,
        land_location,
        status: 'requested',
        created_by_admin: null,
        requested_at: new Date(),
        responded_at: null,
        completed_at: null,
        cancellation_reason: null,
        farmer_name: req.user.full_name,
        farmer_phone: req.user.phone_number || '+94771234567',
        farmer_gn_division: req.user.gn_division || 'Padaviya Town',
        owner_id: machine?.owner_id,
        owner_name: owner?.full_name || machine?.owner_name,
        owner_phone: owner?.phone_number || machine?.owner_phone,
        machine_id: machine?.id,
        machine_brand: machine?.brand,
        machine_model: machine?.model_name,
        machine_type: machine?.machine_type,
        drive_type: machine?.drive_type,
        rate_amount: machine?.rate_amount,
        rate_unit: machine?.rate_unit,
        slot: { ...slot },
      };

      devBookings.unshift(newBooking);

      if (machine) {
        try {
          await notifyBookingRequested({
            ownerId: machine.owner_id,
            farmerName: req.user.full_name,
            machineBrand: machine.brand,
            machineType: machine.machine_type,
            slotDate: slot.slot_date,
            timeRange: `${slot.start_time.substring(0, 5)} - ${slot.end_time.substring(0, 5)}`,
            bookingId: newBooking.id,
          });
        } catch (e) {
          console.warn('Notification error:', e);
        }
      }

      res.status(201).json(newBooking);
      return;
    }

    console.error('Database connection error in createBooking:', err);
    res.status(500).json({ error: 'server_error', message: 'Database connection failed.' });
    return;
  }

  try {
    await client.query('BEGIN');

    // Lock the slot with SELECT ... FOR UPDATE
    const slotRes = await client.query<AvailabilitySlotRecord>(
      'SELECT * FROM availability_slots WHERE id = $1 FOR UPDATE',
      [slot_id]
    );

    if (slotRes.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ error: 'slot_not_found', message: 'Availability slot not found.' });
      return;
    }

    const slot = slotRes.rows[0];
    if (slot.status !== 'open') {
      await client.query('ROLLBACK');
      res.status(409).json({
        error: 'slot_no_longer_available',
        message: 'මෙම වේලාව දැනටමත් වෙන්කරවා ගෙන ඇත (This slot is no longer available).',
      });
      return;
    }

    // Set slot status to pending
    await client.query(
      "UPDATE availability_slots SET status = 'pending', updated_at = now() WHERE id = $1",
      [slot_id]
    );

    // Create booking
    const bookingRes = await client.query<BookingRecord>(
      `INSERT INTO bookings (slot_id, farmer_id, land_location, status, requested_at)
       VALUES ($1, $2, $3, 'requested', now())
       RETURNING *`,
      [slot_id, req.user.id, land_location]
    );

    await client.query('COMMIT');
    res.status(201).json(bookingRes.rows[0]);
  } catch (err: any) {
    if (client) await client.query('ROLLBACK');
    console.error('Transactional booking creation error:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create booking request.' });
  } finally {
    if (client) client.release();
  }
}

// GET /api/v1/bookings/mine?as=farmer|owner
export async function getMyBookings(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { as = 'farmer' } = req.query;
  const isOwner = as === 'owner';

  try {
    const whereClause = isOwner
      ? 'm.owner_id = $1'
      : 'b.farmer_id = $1';

    const sql = `
      SELECT 
        b.*,
        u_farmer.full_name AS farmer_name,
        u_farmer.phone_number AS farmer_phone,
        u_farmer.gn_division AS farmer_gn_division,
        u_owner.id AS owner_id,
        u_owner.full_name AS owner_name,
        u_owner.phone_number AS owner_phone,
        m.id AS machine_id,
        m.brand AS machine_brand,
        m.model_name AS machine_model,
        m.machine_type AS machine_type,
        m.drive_type AS drive_type,
        m.rate_amount,
        m.rate_unit,
        s.slot_date,
        s.start_time,
        s.end_time,
        s.status AS slot_status
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      JOIN users u_farmer ON b.farmer_id = u_farmer.id
      JOIN users u_owner ON m.owner_id = u_owner.id
      WHERE ${whereClause}
      ORDER BY b.requested_at DESC
    `;

    const result = await query(sql, [req.user.id]);
    res.status(200).json(result.rows);
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      let filtered = [...devBookings];

      if (isOwner) {
        filtered = filtered.filter(
          (b) => b.owner_id === req.user!.id || req.user!.role === 'both' || req.user!.role === 'owner'
        );
      } else {
        filtered = filtered.filter((b) => b.farmer_id === req.user!.id);
      }

      // Populate joined slot and machine details if missing
      const enriched = filtered.map((b) => {
        const slot = devSlots.find((s) => s.id === b.slot_id);
        const machine = slot ? devMachines.find((m) => m.id === slot.machine_id) : undefined;
        return {
          ...b,
          slot_date: slot?.slot_date,
          start_time: slot?.start_time,
          end_time: slot?.end_time,
          slot_status: slot?.status,
          machine_brand: machine?.brand || b.machine_brand,
          machine_model: machine?.model_name || b.machine_model,
          machine_type: machine?.machine_type || b.machine_type,
          drive_type: machine?.drive_type || b.drive_type,
          rate_amount: machine?.rate_amount || b.rate_amount,
          rate_unit: machine?.rate_unit || b.rate_unit,
        };
      });

      res.status(200).json(enriched);
      return;
    }

    console.error('Error fetching user bookings:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch bookings.' });
  }
}

// GET /api/v1/bookings/:id
export async function getBookingById(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id } = req.params;

  try {
    const sql = `
      SELECT 
        b.*,
        u_farmer.full_name AS farmer_name,
        u_farmer.phone_number AS farmer_phone,
        u_farmer.gn_division AS farmer_gn_division,
        u_owner.id AS owner_id,
        u_owner.full_name AS owner_name,
        u_owner.phone_number AS owner_phone,
        m.id AS machine_id,
        m.brand AS machine_brand,
        m.model_name AS machine_model,
        m.machine_type AS machine_type,
        m.drive_type AS drive_type,
        m.rate_amount,
        m.rate_unit,
        s.slot_date,
        s.start_time,
        s.end_time,
        s.status AS slot_status
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      JOIN users u_farmer ON b.farmer_id = u_farmer.id
      JOIN users u_owner ON m.owner_id = u_owner.id
      WHERE b.id = $1
    `;

    const result = await query(sql, [id]);
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = result.rows[0];
    if (booking.farmer_id !== req.user.id && booking.owner_id !== req.user.id && req.user.role !== 'admin') {
      res.status(403).json({ error: 'forbidden', message: 'Access denied.' });
      return;
    }

    res.status(200).json(booking);
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const match = devBookings.find((b) => b.id === id);
      if (!match) {
        res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
        return;
      }
      const slot = devSlots.find((s) => s.id === match.slot_id);
      res.status(200).json({
        ...match,
        slot_date: slot?.slot_date,
        start_time: slot?.start_time,
        end_time: slot?.end_time,
      });
      return;
    }

    console.error('Error fetching booking by id:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch booking.' });
  }
}

// PATCH /api/v1/bookings/:id/respond
// Owner confirms or rejects requested booking (FR-5.3)
export async function respondBooking(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id } = req.params;
  const parseResult = respondBookingSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid respond action.',
    });
    return;
  }

  const { action, reason } = parseResult.data;

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const bookingIdx = devBookings.findIndex((b) => b.id === id);
      if (bookingIdx === -1) {
        res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
        return;
      }

      const booking = devBookings[bookingIdx];
      const slot = devSlots.find((s) => s.id === booking.slot_id);

      if (action === 'confirm') {
        booking.status = 'confirmed';
        booking.responded_at = new Date();
        if (slot) slot.status = 'booked';
        try {
          await notifyBookingConfirmed({
            farmerId: booking.farmer_id,
            ownerName: req.user.full_name,
            machineBrand: booking.machine_brand || 'Machine',
            machineType: booking.machine_type || '',
            slotDate: slot?.slot_date || '',
            timeRange: slot ? `${slot.start_time.substring(0, 5)} - ${slot.end_time.substring(0, 5)}` : '',
            bookingId: booking.id,
          });
        } catch (e) {
          console.warn('Notification error:', e);
        }
      } else {
        booking.status = 'rejected';
        booking.responded_at = new Date();
        booking.cancellation_reason = reason || 'Owner declined booking request';
        if (slot) slot.status = 'open'; // Re-open slot for other farmers
        try {
          await notifyBookingRejected({
            farmerId: booking.farmer_id,
            ownerName: req.user.full_name,
            machineBrand: booking.machine_brand || 'Machine',
            slotDate: slot?.slot_date || '',
            bookingId: booking.id,
            reason,
          });
        } catch (e) {
          console.warn('Notification error:', e);
        }
      }

      res.status(200).json({ id: booking.id, status: booking.status });
      return;
    }

    console.error('Database connection error in respondBooking:', err);
    res.status(500).json({ error: 'server_error', message: 'Database connection failed.' });
    return;
  }

  try {
    await client.query('BEGIN');

    // 1. Lock booking
    const bookingRes = await client.query<BookingRecord>(
      `SELECT b.*, m.owner_id 
       FROM bookings b 
       JOIN availability_slots s ON b.slot_id = s.id 
       JOIN machines m ON s.machine_id = m.id 
       WHERE b.id = $1 FOR UPDATE`,
      [id]
    );

    if (bookingRes.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = bookingRes.rows[0];
    if (booking.owner_id !== req.user.id && req.user.role !== 'admin') {
      await client.query('ROLLBACK');
      res.status(403).json({ error: 'forbidden', message: 'Only the machine owner can respond to this booking.' });
      return;
    }

    if (booking.status !== 'requested') {
      await client.query('ROLLBACK');
      res.status(400).json({
        error: 'invalid_status_transition',
        message: `Cannot respond to a booking in '${booking.status}' status.`,
      });
      return;
    }

    // 2. Lock and update slot
    const newBookingStatus = action === 'confirm' ? 'confirmed' : 'rejected';
    const newSlotStatus = action === 'confirm' ? 'booked' : 'open';

    await client.query(
      `UPDATE bookings 
       SET status = $1, responded_at = now(), cancellation_reason = $2 
       WHERE id = $3`,
      [newBookingStatus, action === 'reject' ? reason || null : null, id]
    );

    await client.query(
      'UPDATE availability_slots SET status = $1, updated_at = now() WHERE id = $2',
      [newSlotStatus, booking.slot_id]
    );

    await client.query('COMMIT');
    res.status(200).json({ id, status: newBookingStatus });
  } catch (err: any) {
    if (client) await client.query('ROLLBACK');
    console.error('Error in respondBooking:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to respond to booking.' });
  } finally {
    if (client) client.release();
  }
}

// PATCH /api/v1/bookings/:id/status
// Lifecycle: in_progress -> completed, or cancelled with reason (FR-5.5)
export async function updateBookingStatus(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id } = req.params;
  const parseResult = updateBookingStatusSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid status.',
    });
    return;
  }

  const { status, reason } = parseResult.data;

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const idx = devBookings.findIndex((b) => b.id === id);
      if (idx === -1) {
        res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
        return;
      }

      const booking = devBookings[idx];
      const slot = devSlots.find((s) => s.id === booking.slot_id);

      booking.status = status;
      if (status === 'completed') {
        booking.completed_at = new Date();
      } else if (status === 'cancelled') {
        booking.cancellation_reason = reason || 'Cancelled by user';
        if (slot) slot.status = 'open'; // Re-open slot
      }

      const otherUserId = req.user.id === booking.farmer_id ? (booking.owner_id || '') : booking.farmer_id;
      if (otherUserId) {
        notifyBookingStatusUpdated({
          recipientId: otherUserId,
          status: status as any,
          machineBrand: booking.machine_brand || 'Machine',
          slotDate: slot?.slot_date || '',
          bookingId: booking.id,
          reason,
        }).catch((e) => console.warn('Notification error:', e));
      }

      res.status(200).json({ id: booking.id, status: booking.status });
      return;
    }

    console.error('Database connection error in updateBookingStatus:', err);
    res.status(500).json({ error: 'server_error', message: 'Database connection failed.' });
    return;
  }

  try {
    await client.query('BEGIN');

    const bookingRes = await client.query<BookingRecord>(
      `SELECT b.*, m.owner_id 
       FROM bookings b 
       JOIN availability_slots s ON b.slot_id = s.id 
       JOIN machines m ON s.machine_id = m.id 
       WHERE b.id = $1 FOR UPDATE`,
      [id]
    );

    if (bookingRes.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = bookingRes.rows[0];
    const isOwner = booking.owner_id === req.user.id;
    const isFarmer = booking.farmer_id === req.user.id;
    const isAdmin = req.user.role === 'admin';

    if (!isOwner && !isFarmer && !isAdmin) {
      await client.query('ROLLBACK');
      res.status(403).json({ error: 'forbidden', message: 'Not authorized to change this booking.' });
      return;
    }

    // Cancellation: both parties or admin can cancel with reason
    if (status === 'cancelled') {
      await client.query(
        'UPDATE bookings SET status = $1, cancellation_reason = $2 WHERE id = $3',
        ['cancelled', reason || 'Cancelled by user', id]
      );
      // Revert slot back to open
      await client.query(
        "UPDATE availability_slots SET status = 'open', updated_at = now() WHERE id = $1",
        [booking.slot_id]
      );
    } else if (status === 'completed') {
      await client.query(
        'UPDATE bookings SET status = $1, completed_at = now() WHERE id = $2',
        ['completed', id]
      );
    } else {
      await client.query('UPDATE bookings SET status = $1 WHERE id = $2', [status, id]);
    }

    await client.query('COMMIT');
    res.status(200).json({ id, status });
  } catch (err: any) {
    if (client) await client.query('ROLLBACK');
    console.error('Error updating booking status:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update booking status.' });
  } finally {
    if (client) client.release();
  }
}
