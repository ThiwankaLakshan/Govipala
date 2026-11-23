import { Router } from 'express';
import { authenticateToken, requireRegisteredUser } from '../middleware/auth';
import { deleteAvailabilitySlot } from '../controllers/availabilityController';

const router = Router();

// Delete open availability slot
router.delete('/:slotId', authenticateToken, requireRegisteredUser, deleteAvailabilitySlot);

export default router;
