const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/booking.controller');
const authMiddleware = require('../middleware/authMiddleware'); // Import directly

// All routes require authentication
if (typeof authMiddleware === 'function') {
  router.use(authMiddleware);
} else {
  console.error("CRITICAL: Authentication middleware could not be loaded as a function.");
}

// Calculate fare for a route
router.post('/calculate-fare', bookingController.calculateFare);

// Create a new booking
router.post('/', bookingController.createBooking);

// Get booking history
router.get('/history', bookingController.getBookingHistory);

// Get booking details
router.get('/:id', bookingController.getBookingDetails);

// Update booking status
router.patch('/:id/status', bookingController.updateBookingStatus);

// Cancel booking
router.post('/:id/cancel', bookingController.cancelBooking);

module.exports = router;