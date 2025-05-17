const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

// Protect all routes
router.use(authMiddleware);

// Ride routes
router.post('/request-ride', userController.requestRide);
router.get('/ride-history', userController.getRideHistory);
router.patch('/cancel-ride/:rideId', userController.cancelRide);

module.exports = router;