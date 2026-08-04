const db = require('../models/db');

/**
 * Submit a review for a completed booking.
 */
async function submitReview(req, res) {
  const { booking_id, rating, comment } = req.body;

  if (!booking_id || rating === undefined) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'booking_id and rating are required'
    });
  }

  const ratingVal = parseInt(rating);
  if (isNaN(ratingVal) || ratingVal < 1 || ratingVal > 5) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'rating must be an integer between 1 and 5'
    });
  }

  try {
    // 1. Fetch booking with participants
    const bookingQuery = `
      SELECT b.*, m.owner_id
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      WHERE b.id = $1
    `;
    const bookingRes = await db.query(bookingQuery, [booking_id]);

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Booking not found'
      });
    }

    const booking = bookingRes.rows[0];

    // 2. Validate booking status is completed
    if (booking.status !== 'completed') {
      return res.status(400).json({
        error: 'invalid_action',
        message: 'Reviews can only be submitted for completed bookings'
      });
    }

    // 3. Verify user is participant and establish reviewee
    let revieweeId = '';
    if (req.user.id === booking.farmer_id) {
      revieweeId = booking.owner_id;
    } else if (req.user.id === booking.owner_id) {
      revieweeId = booking.farmer_id;
    } else {
      return res.status(403).json({
        error: 'forbidden',
        message: 'You are not a participant in this booking'
      });
    }

    // 4. Insert review
    const insertQuery = `
      INSERT INTO reviews (booking_id, reviewer_id, reviewee_id, rating, comment, created_at)
      VALUES ($1, $2, $3, $4, $5, now())
      RETURNING id, booking_id, reviewer_id, reviewee_id, rating, comment, created_at
    `;
    const result = await db.query(insertQuery, [
      booking_id,
      req.user.id,
      revieweeId,
      ratingVal,
      comment || null
    ]);

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    // Handle unique constraint failure (reviewer already rated this booking)
    if (error.code === '23505') {
      return res.status(409).json({
        error: 'already_reviewed',
        message: 'You have already submitted a review for this booking'
      });
    }

    console.error('Error submitting review:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while submitting review'
    });
  }
}

/**
 * Get reviews received by a user.
 */
async function getUserReviews(req, res) {
  const { userId } = req.params;

  try {
    const queryText = `
      SELECT r.*, u.full_name as reviewer_name
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      WHERE r.reviewee_id = $1
      ORDER BY r.created_at DESC
    `;
    const result = await db.query(queryText, [userId]);
    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching user reviews:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching reviews'
    });
  }
}

/**
 * Get reviews received by a machine.
 */
async function getMachineReviews(req, res) {
  const { machineId } = req.params;

  try {
    const queryText = `
      SELECT r.*, u.full_name as reviewer_name
      FROM reviews r
      JOIN bookings b ON r.booking_id = b.id
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN users u ON r.reviewer_id = u.id
      WHERE s.machine_id = $1 AND r.reviewee_id = (SELECT owner_id FROM machines WHERE id = $1)
      ORDER BY r.created_at DESC
    `;
    const result = await db.query(queryText, [machineId]);
    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching machine reviews:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching machine reviews'
    });
  }
}

module.exports = {
  submitReview,
  getUserReviews,
  getMachineReviews
};
