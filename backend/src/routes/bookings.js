const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const bookingsController = require('../controllers/bookings');

// All booking routes require authentication
router.use(verifyFirebaseToken);

router.post('/', bookingsController.createBooking);
router.get('/mine', bookingsController.getBookings);
router.patch('/:id/respond', bookingsController.respondToBooking);
router.patch('/:id/status', bookingsController.updateBookingStatus);

module.exports = router;
