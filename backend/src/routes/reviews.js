const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const reviewsController = require('../controllers/reviews');

// All review endpoints require authentication
router.use(verifyFirebaseToken);

router.post('/', reviewsController.submitReview);
router.get('/users/:userId', reviewsController.getUserReviews);
router.get('/machines/:machineId', reviewsController.getMachineReviews);

module.exports = router;
