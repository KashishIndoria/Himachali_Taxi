const express = require('express');
const router = express.Router();
const rideController = require('../controllers/ride.controller');
const auth = require('../middleware/auth');

// Book a new ride
router.post('/book', auth, rideController.bookRide);

// Update ride status and location
router.put('/:rideId/status', auth, rideController.updateRideStatus);

// Get ride history
router.get('/history', auth, rideController.getRideHistory);

// Get current active ride
router.get('/current', auth, rideController.getCurrentRide);

module.exports = router; 