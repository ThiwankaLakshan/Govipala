import { Request, Response } from 'express';
import { query } from '../db';
import { createReviewSchema, hideReviewSchema, ReviewRecord } from '../models/review';
import { devReviews } from '../models/reviewStore';
import { devBookings, devSlots } from '../models/bookingStore';
import { devMachines } from './machineController';
import { devUsers } from '../models/userStore';
import { logAdminAction } from '../services/auditService';
import { sendNotification } from '../services/notificationService';

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

// POST /api/v1/bookings/:id/review (FR-7.1, FR-7.3)
export async function createBookingReview(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id: bookingId } = req.params;
  const parseResult = createReviewSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid review rating or comment.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { rating, comment } = parseResult.data;
  const reviewerId = req.user.id;
  const reviewerName = req.user.full_name;

  try {
    // 1. Fetch booking details from DB
    const bookingRes = await query(
      `SELECT b.*, m.id AS machine_id, m.brand AS machine_brand, m.owner_id 
       FROM bookings b
       JOIN availability_slots s ON b.slot_id = s.id
       JOIN machines m ON s.machine_id = m.id
       WHERE b.id = $1`,
      [bookingId]
    );

    if (bookingRes.rows.length === 0) {
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = bookingRes.rows[0];

    // Must be completed
    if (booking.status !== 'completed') {
      res.status(400).json({
        error: 'invalid_booking_status',
        message: 'Reviews can only be submitted for completed bookings (FR-7.1).',
      });
      return;
    }

    // Must be party to booking
    const isFarmer = booking.farmer_id === reviewerId;
    const isOwner = booking.owner_id === reviewerId;

    if (!isFarmer && !isOwner && req.user.role !== 'admin') {
      res.status(403).json({ error: 'forbidden', message: 'You can only review bookings you participated in.' });
      return;
    }

    const revieweeId = isFarmer ? booking.owner_id : booking.farmer_id;
    const machineId = booking.machine_id;

    // Check if already reviewed (FR-7.3: one review per booking per reviewer)
    const existingRes = await query(
      'SELECT id FROM reviews WHERE booking_id = $1 AND reviewer_id = $2',
      [bookingId, reviewerId]
    );

    if (existingRes.rows.length > 0) {
      res.status(409).json({
        error: 'review_already_exists',
        message: 'You have already submitted a review for this booking (FR-7.3).',
      });
      return;
    }

    const reviewId = `rev-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const now = new Date();

    await query(
      `INSERT INTO reviews (id, booking_id, reviewer_id, reviewee_id, rating, comment, is_hidden, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, false, $7)`,
      [reviewId, bookingId, reviewerId, revieweeId, rating, comment || null, now]
    );

    // Notify reviewee
    await sendNotification({
      userId: revieweeId,
      bookingId,
      channel: 'push',
      title: 'නව ඇගයීමක් ලැබී ඇත (New Review Received)',
      message: `${reviewerName} විසින් ඔබ වෙනුවෙන් තරු ${rating} ක ඇගයීමක් සටහන් කර ඇත.`,
    });

    res.status(201).json({
      id: reviewId,
      booking_id: bookingId,
      reviewer_id: reviewerId,
      reviewer_name: reviewerName,
      reviewee_id: revieweeId,
      machine_id: machineId,
      rating,
      comment: comment || null,
      is_hidden: false,
      created_at: now,
    });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      // In-memory dev fallback
      const booking = devBookings.find((b) => b.id === bookingId);
      if (!booking) {
        res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
        return;
      }

      if (booking.status !== 'completed') {
        res.status(400).json({
          error: 'invalid_booking_status',
          message: 'Reviews can only be submitted for completed bookings (FR-7.1).',
        });
        return;
      }

      const slot = devSlots.find((s) => s.id === booking.slot_id);
      const machine = slot ? devMachines.find((m) => m.id === slot.machine_id) : undefined;
      const ownerId = machine?.owner_id || booking.owner_id;

      const isFarmer = booking.farmer_id === reviewerId;
      const isOwner = ownerId === reviewerId;

      if (!isFarmer && !isOwner && req.user.role !== 'admin') {
        res.status(403).json({ error: 'forbidden', message: 'You can only review bookings you participated in.' });
        return;
      }

      const revieweeId = isFarmer ? (ownerId || '') : booking.farmer_id;
      const machineId = machine?.id;

      // Check existing review
      const alreadyReviewed = devReviews.some(
        (r) => r.booking_id === bookingId && r.reviewer_id === reviewerId
      );

      if (alreadyReviewed) {
        res.status(409).json({
          error: 'review_already_exists',
          message: 'You have already submitted a review for this booking (FR-7.3).',
        });
        return;
      }

      const newReview: ReviewRecord = {
        id: `rev-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
        booking_id: bookingId,
        reviewer_id: reviewerId,
        reviewer_name: reviewerName,
        reviewee_id: revieweeId,
        machine_id: machineId,
        rating,
        comment: comment || null,
        is_hidden: false,
        created_at: new Date(),
      };

      devReviews.unshift(newReview);

      // Update machine rating stats in memory
      if (machine) {
        const machReviews = devReviews.filter((r) => r.machine_id === machine.id && !r.is_hidden);
        const sum = machReviews.reduce((acc, r) => acc + r.rating, 0);
        machine.review_count = machReviews.length;
        machine.average_rating = machReviews.length > 0 ? Number((sum / machReviews.length).toFixed(1)) : 0.0;
      }

      // Notify reviewee
      sendNotification({
        userId: revieweeId,
        bookingId,
        channel: 'push',
        title: 'නව ඇගයීමක් ලැබී ඇත (New Review Received)',
        message: `${reviewerName} විසින් ඔබ වෙනුවෙන් තරු ${rating} ක ඇගයීමක් සටහන් කර ඇත.`,
      }).catch((e) => console.warn('Notification error:', e));

      res.status(201).json(newReview);
      return;
    }

    console.error('Error creating review:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create review.' });
  }
}

// GET /api/v1/users/:id/reviews (FR-7.2, FR-7.4)
export async function getUserReviews(req: Request, res: Response): Promise<void> {
  const { id: userId } = req.params;

  try {
    const sql = `
      SELECT r.*, u.full_name AS reviewer_name
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      WHERE r.reviewee_id = $1 AND r.is_hidden = false
      ORDER BY r.created_at DESC
    `;
    const result = await query(sql, [userId]);
    const reviews = result.rows;

    const total = reviews.length;
    const avg = total > 0
      ? Number((reviews.reduce((acc: number, r: any) => acc + Number(r.rating), 0) / total).toFixed(1))
      : 0.0;

    res.status(200).json({
      reviewee_id: userId,
      average_rating: avg,
      review_count: total,
      reviews,
    });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const filtered = devReviews.filter((r) => r.reviewee_id === userId && !r.is_hidden);
      const total = filtered.length;
      const avg = total > 0
        ? Number((filtered.reduce((acc, r) => acc + r.rating, 0) / total).toFixed(1))
        : 0.0;

      res.status(200).json({
        reviewee_id: userId,
        average_rating: avg,
        review_count: total,
        reviews: filtered,
      });
      return;
    }

    console.error('Error fetching user reviews:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch reviews.' });
  }
}

// GET /api/v1/machines/:id/reviews (FR-7.2, FR-7.4)
export async function getMachineReviews(req: Request, res: Response): Promise<void> {
  const { id: machineId } = req.params;

  try {
    const sql = `
      SELECT r.*, u.full_name AS reviewer_name
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      JOIN bookings b ON r.booking_id = b.id
      JOIN availability_slots s ON b.slot_id = s.id
      WHERE s.machine_id = $1 AND r.is_hidden = false
      ORDER BY r.created_at DESC
    `;
    const result = await query(sql, [machineId]);
    const reviews = result.rows;

    const total = reviews.length;
    const avg = total > 0
      ? Number((reviews.reduce((acc: number, r: any) => acc + Number(r.rating), 0) / total).toFixed(1))
      : 0.0;

    res.status(200).json({
      machine_id: machineId,
      average_rating: avg,
      review_count: total,
      reviews,
    });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const filtered = devReviews.filter((r) => r.machine_id === machineId && !r.is_hidden);
      const total = filtered.length;
      const avg = total > 0
        ? Number((filtered.reduce((acc, r) => acc + r.rating, 0) / total).toFixed(1))
        : 0.0;

      res.status(200).json({
        machine_id: machineId,
        average_rating: avg,
        review_count: total,
        reviews: filtered,
      });
      return;
    }

    console.error('Error fetching machine reviews:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch machine reviews.' });
  }
}

// PATCH /api/v1/admin/reviews/:id/hide (FR-7.4, FR-9.10, FR-9.12)
export async function adminHideReview(req: Request, res: Response): Promise<void> {
  const { id: reviewId } = req.params;
  const parseResult = hideReviewSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'A reason is required to hide a review.',
    });
    return;
  }

  const { is_hidden, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  try {
    const existing = await query('SELECT * FROM reviews WHERE id = $1', [reviewId]);
    if (existing.rows.length === 0) {
      res.status(404).json({ error: 'review_not_found', message: 'Review not found.' });
      return;
    }

    const before = existing.rows[0];
    await query('UPDATE reviews SET is_hidden = $1 WHERE id = $2', [is_hidden, reviewId]);

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: is_hidden ? 'HIDE_REVIEW' : 'UNHIDE_REVIEW',
      target_table: 'reviews',
      target_id: reviewId,
      before_data: { is_hidden: before.is_hidden },
      after_data: { is_hidden },
      reason,
    });

    res.status(200).json({ id: reviewId, is_hidden, message: 'Review visibility updated.' });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const idx = devReviews.findIndex((r) => r.id === reviewId);
      if (idx === -1) {
        res.status(404).json({ error: 'review_not_found', message: 'Review not found.' });
        return;
      }

      const before = { ...devReviews[idx] };
      devReviews[idx].is_hidden = is_hidden;

      // Recalculate machine rating without hidden reviews (FR-7.4)
      const machine = devMachines.find((m) => m.id === devReviews[idx].machine_id);
      if (machine) {
        const visibleReviews = devReviews.filter((r) => r.machine_id === machine.id && !r.is_hidden);
        const sum = visibleReviews.reduce((acc, r) => acc + r.rating, 0);
        machine.review_count = visibleReviews.length;
        machine.average_rating = visibleReviews.length > 0 ? Number((sum / visibleReviews.length).toFixed(1)) : 0.0;
      }

      await logAdminAction({
        admin_id: adminId,
        admin_name: adminName,
        action: is_hidden ? 'HIDE_REVIEW' : 'UNHIDE_REVIEW',
        target_table: 'reviews',
        target_id: reviewId,
        before_data: { is_hidden: before.is_hidden },
        after_data: { is_hidden },
        reason,
      });

      res.status(200).json({ id: reviewId, is_hidden, message: 'Review visibility updated.' });
      return;
    }

    console.error('Error in adminHideReview:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update review visibility.' });
  }
}

// GET /api/v1/admin/reviews (FR-9.10)
export async function getAdminReviews(_req: Request, res: Response): Promise<void> {
  try {
    const sql = `
      SELECT r.*, u.full_name AS reviewer_name, rev.full_name AS reviewee_name
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      JOIN users rev ON r.reviewee_id = rev.id
      ORDER BY r.created_at DESC
    `;
    const result = await query(sql);
    if (result.rows.length > 0) {
      res.status(200).json(result.rows);
      return;
    }
  } catch (_) {
    // fallback
  }

  res.status(200).json(devReviews);
}
