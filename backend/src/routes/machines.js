const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const machinesController = require('../controllers/machines');

// All machine operations require Firebase token verification
router.use(verifyFirebaseToken);

router.post('/', machinesController.createMachine);
router.get('/', machinesController.getMachines);
router.get('/:id', machinesController.getMachineById);
router.patch('/:id', machinesController.updateMachine);
router.delete('/:id', machinesController.deleteMachine);

module.exports = router;
