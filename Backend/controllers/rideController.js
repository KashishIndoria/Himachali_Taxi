const Ride = require('../models/rides/rides');
const User = require('../models/user/User');
const captain = require('../models/captain/captain');
const { findCaptainSocketId } = require('../services/locationservices'); // Import the helper
const { getIO } = require('../config/socket'); // Import socket getter
const mongoose = require('mongoose'); // Import mongoose for ObjectId validation
const logger = require('../utils/logger'); // Assuming logger is configured

// Create a new ride request (Initiation via HTTP)
exports.createRideRequest = async (req, res) => {
  try {
    const {
      pickupLocation,
      dropLocation,
      fare, // Fare might be estimated on the client or calculated later
      paymentMethod, // Optional: Get payment method
      estimatedDistance, // Optional: Client might provide estimate
      estimatedDuration // Optional: Client might provide estimate
    } = req.body;

    // Validate required fields
    if (!pickupLocation || !pickupLocation.latitude || !pickupLocation.longitude || !pickupLocation.address ||
        !dropLocation || !dropLocation.latitude || !dropLocation.longitude || !dropLocation.address ||
        fare === undefined) { // Check for fare presence
      return res.status(400).json({ message: 'Missing required fields: pickupLocation (lat, long, address), dropLocation (lat, long, address), and fare are required.' });
    }

    // Verify user exists (req.user should be populated by authMiddleware)
    const user = await User.findById(req.user.id).select('firstName lastName phone rating');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Create the initial Ride document
    const newRide = new Ride({
      userId: req.user.id,
      pickupLocation,
      dropLocation,
      fare, // Store the initial fare estimate
      status: 'requested', // Initial status
      paymentMethod: paymentMethod || 'cash' // Default payment method if not provided
    });

    await newRide.save();
    console.log(`Ride document created: ${newRide._id} by User ${req.user.id}`);

    // Get the Socket.IO instance
    const io = getIO();

    // Emit the 'requestRide' event to the socket server to handle matching and notifications
    // Pass all necessary details for the socket handler
    io.emit('requestRide', {
        rideId: newRide._id, // Pass the newly created ride ID
        userId: req.user.id,
        pickupLocation: newRide.pickupLocation,
        dropLocation: newRide.dropLocation,
        fare: newRide.fare,
        paymentMethod: newRide.paymentMethod,
        // Pass user details for captain notification
        passengerDetails: {
            id: user._id,
            name: `${user.firstName} ${user.lastName || ''}`.trim(),
            phone: user.phone,
            rating: user.rating || 5 // Default rating if none
        },
        // Pass optional estimates if available
        estimatedDistance: estimatedDistance,
        estimatedDuration: estimatedDuration,
        requestTime: newRide.createdAt
    });

    console.log(`Emitted 'requestRide' event for Ride ${newRide._id}`);

    // Respond to the client immediately, indicating the request is being processed
    res.status(201).json({
      message: 'Ride request initiated successfully. Searching for drivers...',
      ride: newRide, // Send back the created ride document
    });

  } catch (error) {
    // logger.error(`Error in createRideRequest: ${error.message}`); // Use logger if available
    console.error(`Error in createRideRequest: ${error.message}`, error.stack);
    res.status(500).json({ message: 'Server error while creating ride request' });
  }
};

// Get ride details
exports.getRideDetails = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    // Check if the user is either the rider or the captain
    if (
      ride.userId.toString() !== req.user.id &&
      ride.captainId?.toString() !== req.user.id
    ) {
      return res.status(403).json({ message: 'Not authorized to view this ride' });
    }

    // Populate captain details if available
    let rideDetails = ride;
    if (ride.captainId) {
      rideDetails = await Ride.findById(req.params.id)
        .populate('captainId', 'firstName lastName phone profileImage rating vehicleDetails');
    }

    res.json(rideDetails);
  } catch (error) {
    logger.error(`Error in getRideDetails: ${error.message}`);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get user ride history
exports.getUserRideHistory = async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    
    const query = { userId: req.user.id };
    
    if (status && ['requested', 'accepted', 'completed', 'cancelled'].includes(status)) {
      query.status = status;
    }

    const options = {
      skip: (page - 1) * limit,
      limit: parseInt(limit),
      sort: { updatedAt: -1 },
    };

    const rides = await Ride.find(query, null, options)
      .populate('captainId', 'firstName lastName profileImage vehicleDetails');
    
    const totalRides = await Ride.countDocuments(query);

    res.json({
      rides,
      totalPages: Math.ceil(totalRides / limit),
      currentPage: page,
      totalRides,
    });
  } catch (error) {
    logger.error(`Error in getUserRideHistory: ${error.message}`);
    res.status(500).json({ message: 'Server error' });
  }
};

// Cancel ride by user
exports.cancelRideByUser = async (req, res) => {
  try {
    const { rideId, reason } = req.body;
    
    if (!rideId) {
      return res.status(400).json({ message: 'Ride ID is required' });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to cancel this ride' });
    }

    if (!['Pending', 'Accepted'].includes(ride.status)) {
      return res.status(400).json({ message: `Ride cannot be cancelled in status: ${ride.status}` });
    }

    ride.status = 'CancelledByUser'; // Update status to cancelled  
    ride.cancellationReason = reason || 'Cancelled by user';
    ride.cancelledAt = new Date(); // Optional: Store cancellation time
    await ride.save();

    // Notify the captain if they were assigned
    // Use 'captain' field from updated Ride model
    if (ride.captainId) { // Assuming captainId holds the ID of the assigned captain
      const io = getIO();
      // Use the helper function to find the socket ID
      const captainSocketId = await findCaptainSocketId(ride.captainId.toString()); // Ensure ID is a string if needed by the helper

      if (io && captainSocketId) {
      // Emit to the specific socket ID
      io.to(captainSocketId).emit('rideCancelled', {
        rideId: ride._id, // Use _id for consistency
        cancelledAt: ride.cancelledAt,
        reason: ride.cancellationReason,
        cancelledBy: 'user' // Indicate who cancelled
      });
      logger.info(`Notified captain ${ride.captainId} via socket ${captainSocketId} about cancelled ride ${ride._id}`);
      } else {
       logger.warn(`Could not find active socket for captain ${ride.captainId} to notify about cancellation.`);
      }
    }

    res.json({ message: 'Ride cancelled successfully', ride });
  } catch (error) {
    logger.error(`Error in cancelRideByUser: ${error.message}`, error.stack);
    res.status(500).json({ message: 'Server error' });
  }
};
