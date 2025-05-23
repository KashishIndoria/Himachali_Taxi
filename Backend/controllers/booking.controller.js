const Booking = require('../models/booking.model');
const { calculateDistance } = require('../utils/location.utils');
const { emitSocketEvent } = require('../config/socket'); // Corrected path

// Constants for fare calculation
const BASE_FARE = 50;
const PER_KM_RATE = 15;
const MIN_FARE = 100;
const SURGE_MULTIPLIER = 1.5;

// Calculate fare based on distance and time
const calculateFare = (distance) => {
  let fare = BASE_FARE + (distance * PER_KM_RATE);
  
  // Apply surge pricing during peak hours (example: 5 PM to 8 PM)
  const currentHour = new Date().getHours();
  if (currentHour >= 17 && currentHour <= 20) {
    fare *= SURGE_MULTIPLIER;
  }
  
  return Math.max(fare, MIN_FARE);
};

// Create a new booking
exports.createBooking = async (req, res) => {
  try {
    const {
      pickupLocation,
      dropoffLocation,
      pickupAddress,
      dropoffAddress,
      paymentMethod
    } = req.body;

    // Calculate distance and fare
    const distance = calculateDistance(
      pickupLocation.coordinates,
      dropoffLocation.coordinates
    );
    const estimatedFare = calculateFare(distance);

    const booking = new Booking({
      userId: req.user._id,
      pickupLocation: {
        type: 'Point',
        coordinates: pickupLocation.coordinates,
        address: pickupAddress
      },
      dropoffLocation: {
        type: 'Point',
        coordinates: dropoffLocation.coordinates,
        address: dropoffAddress
      },
      estimatedFare,
      paymentMethod
    });

    await booking.save();

    // Emit socket event for nearby captains
    emitSocketEvent('newBooking', {
      bookingId: booking._id,
      pickupLocation: booking.pickupLocation,
      estimatedFare: booking.estimatedFare
    });

    res.status(201).json({
      success: true,
      data: booking
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Get booking history for a user
exports.getBookingHistory = async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user._id })
      .sort({ bookingTime: -1 })
      .limit(10);

    res.json({
      success: true,
      data: bookings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Get booking details
exports.getBookingDetails = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        error: 'Booking not found'
      });
    }

    // Check if user is authorized to view this booking
    if (booking.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to view this booking'
      });
    }

    res.json({
      success: true,
      data: booking
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Update booking status
exports.updateBookingStatus = async (req, res) => {
  try {
    const { status, captainId, actualFare } = req.body;
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        error: 'Booking not found'
      });
    }

    // Update booking status and related fields
    booking.status = status;
    if (captainId) booking.captainId = captainId;
    if (actualFare) booking.actualFare = actualFare;

    // Set timestamps based on status
    switch (status) {
      case 'accepted':
        booking.acceptedTime = new Date();
        break;
      case 'completed':
        booking.completedTime = new Date();
        break;
    }

    await booking.save();

    // Emit socket event for status update
    emitSocketEvent('bookingStatusUpdate', {
      bookingId: booking._id,
      status: booking.status,
      captainId: booking.captainId,
      actualFare: booking.actualFare
    });

    res.json({
      success: true,
      data: booking
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Cancel booking
exports.cancelBooking = async (req, res) => {
  try {
    const { reason } = req.body;
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        error: 'Booking not found'
      });
    }

    // Check if booking can be cancelled
    if (['completed', 'cancelled'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        error: 'Booking cannot be cancelled'
      });
    }

    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    await booking.save();

    // Emit socket event for cancellation
    emitSocketEvent('bookingCancelled', {
      bookingId: booking._id,
      reason: reason
    });

    res.json({
      success: true,
      data: booking
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Calculate fare for a route
exports.calculateFare = async (req, res) => {
  try {
    const { pickupLocation, dropoffLocation } = req.body;

    const distance = calculateDistance(
      pickupLocation.coordinates,
      dropoffLocation.coordinates
    );
    const estimatedFare = calculateFare(distance);

    res.json({
      success: true,
      data: {
        distance,
        estimatedFare
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};