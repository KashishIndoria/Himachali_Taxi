const express = require('express');
const router = express.Router();
const captainController = require('../controllers/captainController');
const protect = require('../middleware/authMiddleware');

console.log("Available controller functions:", Object.keys(captainController));

// Profile Management Routes
router.get('/profile/:captainId', protect, captainController.getCaptainProfile);
router.put('/profile', protect, captainController.updateCaptainProfile);
router.put('/update-profile-image', protect, captainController.updateProfileImage);

// Status and Availability Routes
router.get('/status', protect, captainController.getCaptainStatus);
router.post('/toggle-availability', protect, captainController.toggleAvailability);
router.post('/update-location', protect, captainController.updateLocation);

// Ride Management Routes
router.get('/rides', protect, captainController.getRideHistory);
router.get('/earnings', protect, captainController.getEarnings);
router.get('/available-rides', protect, captainController.getAvailableRides);
router.post('/accept-ride', protect, captainController.acceptRideRequest);
router.post('/decline-ride/:rideId', protect, captainController.declineRideRequest);
router.post('/complete-ride', protect, captainController.completeRide);
router.post('/cancel-ride', protect, captainController.cancelRideByDriver);
router.post('/arrive', protect, captainController.markAsArrived);
router.post('/start-ride', protect, captainController.startRide);

module.exports = router;