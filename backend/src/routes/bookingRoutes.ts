import { Router } from 'express';
import { authenticateToken, requireRegisteredUser } from '../middleware/auth';
import {
  createBooking,
  getMyBookings,
  getBookingById,
  respondBooking,
  updateBookingStatus,
} from '../controllers/bookingController';
import { createBookingReview } from '../controllers/reviewController';

const router = Router();

// All booking operations require authenticated registered user
router.use(authenticateToken);
router.use(requireRegisteredUser);

// Booking creation and querying
router.post('/', createBooking);
router.get('/mine', getMyBookings);
router.get('/:id', getBookingById);

// Owner response and lifecycle updates
router.patch('/:id/respond', respondBooking);
router.patch('/:id/status', updateBookingStatus);

// Reviews on completed bookings (Phase 5: FR-7.1)
router.post('/:id/review', createBookingReview);

export default router;
