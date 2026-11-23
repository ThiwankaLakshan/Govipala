import { Router } from 'express';
import { authenticateToken, requireRegisteredUser } from '../middleware/auth';
import { registerUser, getMe, updateMe } from '../controllers/userController';
import { getUserReviews } from '../controllers/reviewController';

const router = Router();

router.post('/register', authenticateToken, registerUser);
router.get('/me', authenticateToken, getMe);
router.patch('/me', authenticateToken, requireRegisteredUser, updateMe);

// Public user reviews (Phase 5: FR-7.2)
router.get('/:id/reviews', getUserReviews);

export default router;
