const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/booking.controller');
const { authenticate } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(authenticate);

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