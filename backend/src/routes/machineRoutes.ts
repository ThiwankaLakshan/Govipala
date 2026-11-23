import { Router } from 'express';
import { authenticateToken, requireRegisteredUser } from '../middleware/auth';
import {
  createMachine,
  getMachines,
  getMachineById,
  updateMachine,
  deleteMachine,
} from '../controllers/machineController';
import {
  createMachineAvailability,
  getMachineAvailability,
} from '../controllers/availabilityController';
import { getMachineReviews } from '../controllers/reviewController';

const router = Router();

// Browsing machines does not require auth, or can use it if token present
router.get('/', getMachines);
router.get('/:id', getMachineById);

// Public machine reviews (Phase 5: FR-7.2)
router.get('/:id/reviews', getMachineReviews);

// Availability slots for a machine
router.get('/:id/availability', getMachineAvailability);
router.post('/:id/availability', authenticateToken, requireRegisteredUser, createMachineAvailability);

// Owner operations require authenticated, registered user
router.post('/', authenticateToken, requireRegisteredUser, createMachine);
router.patch('/:id', authenticateToken, requireRegisteredUser, updateMachine);
router.delete('/:id', authenticateToken, requireRegisteredUser, deleteMachine);

export default router;
