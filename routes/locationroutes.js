const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const authMiddleware = require('../middleware/authMiddleware');

// Protect all routes
router.use(authMiddleware);

// Location routes
router.post('/update', locationController.updateLocation);
router.get('/get/:rideId', locationController.getLocation);

module.exports = router;