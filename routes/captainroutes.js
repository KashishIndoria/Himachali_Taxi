const express = require('express');
const router = express.Router();
const captainController = require('../controllers/captainController');
const protect = require('../middleware/authMiddleware');

console.log("Available controller functions:", Object.keys(captainController));

// Get captain's profile
router.get('/profile/:captainId', protect, captainController.getCaptainProfile);

// Update captain's profile
router.put('/profile', protect, captainController.updateCaptainProfile);

// Update captain's profile image
router.put('/update-profile-image', protect, captainController.updateProfileImage);

// Get captain status
router.get('/status', protect, captainController.getCaptainStatus);

// Toggle captain availability
router.post('/toggle-availability', protect, captainController.toggleAvailability);

// Update captain location
router.post('/update-location', protect, captainController.updateLocation);

// Get captain ride history
router.get('/rides', protect, captainController.getRideHistory);

// Get captain earnings
router.get('/earnings', protect, captainController.getEarnings);

// Get available rides near the captain
router.get('/available-rides', protect, captainController.getAvailableRides);

// Accept a ride request
router.post('/accept-ride', protect, captainController.acceptRideRequest);

// Decline a ride request
router.post('/decline-ride', protect, captainController.declineRideRequest);

// Complete a ride
router.post('/complete-ride', protect, captainController.completeRide);

// Cancel a ride
router.post('/cancel-ride', protect, captainController.cancelRideByDriver);

module.exports = router;