import { Router } from 'express';
import { authenticateToken, requireAdmin } from '../middleware/auth';
import { getMyNotifications, getAdminNotificationLog } from '../controllers/notificationController';

const router = Router();

router.get('/mine', authenticateToken, getMyNotifications);
router.get('/log', authenticateToken, requireAdmin, getAdminNotificationLog);

export default router;
