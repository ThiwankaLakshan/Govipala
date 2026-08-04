const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const usersController = require('../controllers/users');

// All user routes require Firebase token verification
router.use(verifyFirebaseToken);

router.post('/register', usersController.register);
router.get('/me', usersController.getMe);
router.patch('/me', usersController.updateMe);

module.exports = router;
