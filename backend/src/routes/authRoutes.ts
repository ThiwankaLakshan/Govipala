import { Router } from 'express';
import { login, directRegister, getDemoCredentials } from '../controllers/authController';

const router = Router();

router.get('/demo-credentials', getDemoCredentials);
router.post('/login', login);
router.post('/register', directRegister);

export default router;
