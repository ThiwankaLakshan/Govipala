const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const availabilityController = require('../controllers/availability');

// All availability routes require authentication
router.use(verifyFirebaseToken);

// Map paths exactly as specified in the API Spec
router.post('/machines/:id/availability', availabilityController.createSlots);
router.get('/machines/:id/availability', availabilityController.getSlots);
router.delete('/availability/:slotId', availabilityController.deleteSlot);

module.exports = router;
