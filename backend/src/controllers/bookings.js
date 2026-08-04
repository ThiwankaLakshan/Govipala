const db = require('../models/db');
const dispatchNotification = require('../services/dispatchNotification');

/**
 * Farmer requests booking on an open slot.
 * Enforces transaction-locking to prevent concurrent conflicts.
 */
async function createBooking(req, res) {
  const { slot_id, land_location, land_size_acres } = req.body;

  if (!slot_id || land_size_acres === undefined) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'slot_id and land_size_acres are required'
    });
  }

  const acres = parseFloat(land_size_acres);
  if (isNaN(acres) || acres <= 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'land_size_acres must be a positive number'
    });
  }

  const client = await db.getClient();

  try {
    // Start transactional block
    await client.query('BEGIN');

    // 1. Lock the availability slot row for update
    const slotQuery = `
      SELECT s.*, m.owner_id, m.machine_type
      FROM availability_slots s
      JOIN machines m ON s.machine_id = m.id
      WHERE s.id = $1 FOR UPDATE
    `;
    const slotRes = await client.query(slotQuery, [slot_id]);

    if (slotRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'not_found',
        message: 'Availability slot not found'
      });
    }

    const slot = slotRes.rows[0];

    // 2. Check if the slot is open
    if (slot.status !== 'open') {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'slot_no_longer_available',
        message: `This slot is currently ${slot.status} and cannot be booked`
      });
    }

    // 3. Mark slot as pending
    await client.query(
      'UPDATE availability_slots SET status = \'pending\', updated_at = now() WHERE id = $1',
      [slot_id]
    );

    // 4. Create the booking entry
    const insertBookingText = `
      INSERT INTO bookings (slot_id, farmer_id, land_location, land_size_acres, status, requested_at)
      VALUES ($1, $2, $3, $4, 'requested', now())
      RETURNING id, slot_id, farmer_id, land_location, land_size_acres, status, requested_at
    `;
    const bookingRes = await client.query(insertBookingText, [
      slot_id,
      req.user.id,
      land_location || null,
      acres
    ]);

    // Commit changes
    await client.query('COMMIT');

    // Dispatch notification (owner alert)
    dispatchNotification(
      slot.owner_id,
      bookingRes.rows[0].id,
      'New Booking Request',
      `Farmer ${req.user.full_name} has requested a slot for your ${slot.machine_type.replace(/_/g, ' ')} on ${slot.slot_date}`
    );

    return res.status(201).json(bookingRes.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error reserving booking slot:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while processing reservation request'
    });
  } finally {
    client.release();
  }
}

/**
 * Retrieve current user's bookings.
 * Query param: as = 'farmer' | 'owner'
 */
async function getBookings(req, res) {
  const { as } = req.query;

  if (as !== 'farmer' && as !== 'owner') {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'Query parameter "as" must be either "farmer" or "owner"'
    });
  }

  try {
    let queryText = '';
    const params = [req.user.id];

    if (as === 'farmer') {
      queryText = `
        SELECT b.*, s.slot_date, s.start_time, s.end_time, m.machine_type, m.model_name, u.full_name as owner_name
        FROM bookings b
        JOIN availability_slots s ON b.slot_id = s.id
        JOIN machines m ON s.machine_id = m.id
        JOIN users u ON m.owner_id = u.id
        WHERE b.farmer_id = $1
        ORDER BY s.slot_date DESC, s.start_time DESC
      `;
    } else {
      queryText = `
        SELECT b.*, s.slot_date, s.start_time, s.end_time, m.machine_type, m.model_name, u.full_name as farmer_name
        FROM bookings b
        JOIN availability_slots s ON b.slot_id = s.id
        JOIN machines m ON s.machine_id = m.id
        JOIN users u ON b.farmer_id = u.id
        WHERE m.owner_id = $1
        ORDER BY s.slot_date DESC, s.start_time DESC
      `;
    }

    const result = await db.query(queryText, params);
    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching bookings list:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching bookings list'
    });
  }
}

/**
 * Owner confirms or rejects a booking request.
 */
async function respondToBooking(req, res) {
  const { id: bookingId } = req.params;
  const { action } = req.body; // 'confirm' | 'reject'

  if (action !== 'confirm' && action !== 'reject') {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'action must be either "confirm" or "reject"'
    });
  }

  const client = await db.getClient();

  try {
    await client.query('BEGIN');

    // 1. Fetch booking with ownership details
    const bookingQuery = `
      SELECT b.*, m.owner_id, m.machine_type, s.id as slot_id, s.status as slot_status, s.slot_date
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      WHERE b.id = $1 FOR UPDATE
    `;
    const bookingRes = await client.query(bookingQuery, [bookingId]);

    if (bookingRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'not_found',
        message: 'Booking not found'
      });
    }

    const booking = bookingRes.rows[0];

    // 2. Authorize
    if (booking.owner_id !== req.user.id) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        error: 'forbidden',
        message: 'You are not the owner of this machine listing'
      });
    }

    if (booking.status !== 'requested') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'invalid_action',
        message: `Booking has already been responded to (Current status: ${booking.status})`
      });
    }

    // 3. Apply actions
    let newBookingStatus = '';
    let newSlotStatus = '';

    if (action === 'confirm') {
      newBookingStatus = 'confirmed';
      newSlotStatus = 'booked';
    } else {
      newBookingStatus = 'rejected';
      newSlotStatus = 'open';
    }

    await client.query(
      'UPDATE bookings SET status = $1, responded_at = now() WHERE id = $2',
      [newBookingStatus, bookingId]
    );

    await client.query(
      'UPDATE availability_slots SET status = $1, updated_at = now() WHERE id = $2',
      [newSlotStatus, booking.slot_id]
    );

    await client.query('COMMIT');

    // Notify Farmer
    dispatchNotification(
      booking.farmer_id,
      bookingId,
      action === 'confirm' ? 'Booking Confirmed' : 'Booking Declined',
      action === 'confirm' 
        ? `Your booking request for a ${booking.machine_type.replace(/_/g, ' ')} on ${booking.slot_date} was confirmed by the owner.`
        : `Your booking request for a ${booking.machine_type.replace(/_/g, ' ')} on ${booking.slot_date} was declined by the owner.`
    );

    return res.status(200).json({
      id: bookingId,
      status: newBookingStatus
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error responding to booking:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while responding to booking'
    });
  } finally {
    client.release();
  }
}

/**
 * Update booking lifecycle status.
 * Actions: in_progress, completed, cancelled
 */
async function updateBookingStatus(req, res) {
  const { id: bookingId } = req.params;
  const { status } = req.body;

  const ALLOWED_STATUSES = ['in_progress', 'completed', 'cancelled'];
  if (!ALLOWED_STATUSES.includes(status)) {
    return res.status(400).json({
      error: 'validation_failed',
      message: `status must be one of: ${ALLOWED_STATUSES.join(', ')}`
    });
  }

  const client = await db.getClient();

  try {
    await client.query('BEGIN');

    // 1. Fetch booking with ownership details
    const bookingQuery = `
      SELECT b.*, m.owner_id, m.machine_type, s.id as slot_id, s.status as slot_status, s.slot_date
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      WHERE b.id = $1 FOR UPDATE
    `;
    const bookingRes = await client.query(bookingQuery, [bookingId]);

    if (bookingRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'not_found',
        message: 'Booking not found'
      });
    }

    const booking = bookingRes.rows[0];

    // 2. Perform validations based on new lifecycle request
    if (status === 'in_progress') {
      // Must be owner to mark job in progress, booking must be confirmed
      if (booking.owner_id !== req.user.id) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'forbidden', message: 'Only machine owners can change status to in_progress' });
      }
      if (booking.status !== 'confirmed') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'invalid_action', message: 'Job must be confirmed before marking in progress' });
      }
      
      await client.query('UPDATE bookings SET status = \'in_progress\' WHERE id = $1', [bookingId]);
    } 
    
    else if (status === 'completed') {
      // Must be owner to complete, booking must be in_progress
      if (booking.owner_id !== req.user.id) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'forbidden', message: 'Only machine owners can mark jobs completed' });
      }
      if (booking.status !== 'in_progress') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'invalid_action', message: 'Job must be in progress before marking completed' });
      }
      
      await client.query('UPDATE bookings SET status = \'completed\', completed_at = now() WHERE id = $1', [bookingId]);
    } 
    
    else if (status === 'cancelled') {
      // Either farmer can cancel requested/confirmed, or owner can cancel requested/confirmed.
      // Cannot cancel if completed or in_progress.
      const isOwner = booking.owner_id === req.user.id;
      const isFarmer = booking.farmer_id === req.user.id;

      if (!isOwner && !isFarmer) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'forbidden', message: 'You do not participate in this booking' });
      }

      if (['in_progress', 'completed', 'cancelled', 'rejected'].includes(booking.status)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'invalid_action', message: `Cannot cancel a booking in status: ${booking.status}` });
      }

      const cancellationReason = req.body.cancellation_reason || 'Cancelled by user';

      await client.query(
        'UPDATE bookings SET status = \'cancelled\', cancellation_reason = $1 WHERE id = $2',
        [cancellationReason, bookingId]
      );

      // Release slot back to open
      await client.query(
        'UPDATE availability_slots SET status = \'open\', updated_at = now() WHERE id = $1',
        [booking.slot_id]
      );
    }

    await client.query('COMMIT');

    // Dispatch status change notifications
    if (status === 'completed') {
      dispatchNotification(
        booking.farmer_id,
        bookingId,
        'Job Completed',
        `Your booking for a ${booking.machine_type.replace(/_/g, ' ')} on ${booking.slot_date} is marked completed. Please rate the service.`
      );
    } else if (status === 'cancelled') {
      const isCancelledByFarmer = req.user.id === booking.farmer_id;
      if (isCancelledByFarmer) {
        dispatchNotification(
          booking.owner_id,
          bookingId,
          'Booking Cancelled',
          `Farmer has cancelled the booking for ${booking.machine_type.replace(/_/g, ' ')} on ${booking.slot_date}`
        );
      } else {
        dispatchNotification(
          booking.farmer_id,
          bookingId,
          'Booking Cancelled',
          `Owner has cancelled your booking for ${booking.machine_type.replace(/_/g, ' ')} on ${booking.slot_date}`
        );
      }
    }

    return res.status(200).json({
      id: bookingId,
      status: status
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating booking status:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while updating booking status'
    });
  } finally {
    client.release();
  }
}

module.exports = {
  createBooking,
  getBookings,
  respondToBooking,
  updateBookingStatus
};
