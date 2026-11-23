import { Router } from 'express';
import { authenticateToken, requireAdmin } from '../middleware/auth';
import {
  getAdminStats,
  getAdminUsers,
  getAdminUserById,
  createAdminUser,
  updateAdminUser,
  updateAdminUserStatus,
  getAdminMachines,
  updateAdminMachine,
  deactivateAdminMachine,
  getAdminAuditLogs,
  getAdminBookings,
  createAdminBooking,
  overrideAdminBookingStatus,
  adminCreateMachineAvailability,
  adminUpdateSlot,
  adminDeleteSlot,
} from '../controllers/adminController';
import { adminHideReview, getAdminReviews } from '../controllers/reviewController';

const router = Router();

// Enforce authentication & admin authorization for all /admin routes
router.use(authenticateToken);
router.use(requireAdmin);

// Dashboard stats
router.get('/stats', getAdminStats);

// User management
router.get('/users', getAdminUsers);
router.get('/users/:id', getAdminUserById);
router.post('/users', createAdminUser);
router.patch('/users/:id', updateAdminUser);
router.patch('/users/:id/status', updateAdminUserStatus);

// Machine management
router.get('/machines', getAdminMachines);
router.patch('/machines/:id', updateAdminMachine);
router.delete('/machines/:id', deactivateAdminMachine);

// Machine availability management
router.post('/machines/:id/availability', adminCreateMachineAvailability);
router.patch('/availability/:slotId', adminUpdateSlot);
router.delete('/availability/:slotId', adminDeleteSlot);

// Booking management
router.get('/bookings', getAdminBookings);
router.post('/bookings', createAdminBooking);
router.patch('/bookings/:id', overrideAdminBookingStatus);

// Reviews moderation (Phase 5: FR-7.4, FR-9.10)
router.get('/reviews', getAdminReviews);
router.patch('/reviews/:id/hide', adminHideReview);

// Audit log
router.get('/audit-log', getAdminAuditLogs);

export default router;
