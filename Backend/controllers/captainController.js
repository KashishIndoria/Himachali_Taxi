const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const { getIO } = require('../config/socket');

/**
 * Get captain profile
 */
exports.getCaptainProfile = async (req, res) => {
  try {
    console.log(req.params.captainId);

    const captain = await Captain.findById(req.params.captainId)
      .select('-password -__v');

    console.log(captain);

    if (!captain) {
      return res.status(404).json({ success: false, message: 'Captain not found' });
    }

    res.status(200).json({
      success: true,
      data: captain
    });
  } catch (error) {
    logger.error('Error fetching captain profile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Update captain profile
 */
exports.updateCaptainProfile = async (req, res) => {
  try {
    const { firstName, lastName, phone, address, vehicleDetails } = req.body;

    // Fields to update
    const updateFields = {};
    if (firstName) updateFields.firstName = firstName;
    if (lastName) updateFields.lastName = lastName;
    if (phone) updateFields.phone = phone;
    if (address) updateFields.address = address;
    if (vehicleDetails) updateFields.vehicleDetails = vehicleDetails;

    const captain = await Captain.findByIdAndUpdate(
      req.user.id,
      { $set: updateFields },
      { new: true, runValidators: true }
    ).select('-password -__v');

    if (!captain) {
      return res.status(404).json({ success: false, message: 'Captain not found' });
    }

    res.status(200).json({
      success: true,
      data: captain,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    logger.error('Error updating captain profile:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: 'Validation failed', errors: error.errors });
  }
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Update profile image
 */
exports.updateProfileImage = async (req, res) => {
  try {
    const { profileImageUrl } = req.body;

    if (!profileImageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Profile image URL is required'
      });
    }

    const captain = await Captain.findByIdAndUpdate(
      req.user.id,
      { $set: { profileImage: profileImageUrl } },
      { new: true }
    ).select('-password -__v');

    if (!captain) {
      return res.status(404).json({ success: false, message: 'Captain not found' });
    }

    res.status(200).json({
      success: true,
      data: { profileImage: captain.profileImage },
      message: 'Profile image updated successfully'
    });
  } catch (error) {
    logger.error('Error updating profile image:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Get captain status
 */
exports.getCaptainStatus = async (req, res) => {
  try {
    const captainId = req.query.id || req.user.id;

    if (!mongoose.Types.ObjectId.isValid(captainId)) {
      return res.status(400).json({ success: false, message: 'Invalid Captain ID format' });
  }

  const captain = await Captain.findById(captainId)
  .select('isAvailable isOnline lastSeen location');

    if (!captain) {
      return res.status(404).json({ success: false, message: 'Captain not found' });
    }

    res.status(200).json({
      success: true,
      data: {
        isAvailable: captain.isAvailable,
        isOnline: captain.isOnline,
        lastSeen: captain.lastSeen,
        location: captain.location
      }
    });
  } catch (error) {
    logger.error('Error fetching captain status:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Toggle captain availability
 */
exports.toggleAvailability = async (req, res) => {
  const captainId = req.user.id; // Get captain ID from authenticated user
  const { isAvailable } = req.body; // Expecting { isAvailable: true/false } in body

  console.log('-------Toggle Availability Request-----');
  console.log(`Captain ID: ${captainId}`);
  console.log(`Request isAvailable: ${isAvailable}`);

  if (typeof isAvailable !== 'boolean') {
      return res.status(400).json({ success: false, message: 'Invalid input: isAvailable must be true or false.' });
  }

  try {
      const captain = await Captain.findById(captainId).select('isOnline isAvailable'); // Select fields needed
      if (!captain) {
        console.log("Captain not found.");
          return res.status(404).json({ success: false, message: 'Captain not found.' });
      }

      // Prevent going available if offline (socket disconnected)
      if (isAvailable && !captain.isOnline) {
           logger.warn(`Captain ${captainId} attempted to go available while offline.`);
           // Return current state instead of error? Or error? Let's return error for clarity.
           return res.status(400).json({ success: false, message: 'Cannot go available while offline. Ensure socket is connected.' });
      }

      // Update the captain's availability status if changed
      if (captain.isAvailable !== isAvailable) {
          captain.isAvailable = isAvailable;
          await captain.save();
          logger.info(`Captain ${captainId} availability set to: ${isAvailable}`);

          // Emit availability change via Socket.IO
          const io = getIO();
          if(io) {
              io.emit('captainAvailabilityChanged', {
                  captainId: captain._id,
                  isAvailable,
                  // location: captain.location // Location might not be loaded here, fetch if needed
              });
              logger.info(`Emitted captainAvailabilityChanged for ${captain._id}: ${isAvailable}`);
          }
      } else {
           logger.info(`Captain ${captainId} availability already set to: ${isAvailable}`);
      }

      res.status(200).json({
          success: true,
          data: {
          isAvailable: captain.isAvailable,
          isOnline: captain.isOnline // Reflect current online status
          },
          message: `Availability status is now ${captain.isAvailable ? 'available' : 'unavailable'}`
      });

  } catch (error) {
      logger.error(`Error toggling availability for captain \${captainId}:`, error);
      res.status(500).json({ success: false, message: 'Server error updating availability.', error: error.message });
  }
};

/**
 * Update captain location
 */
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, heading, speed } = req.body;

    // Validate required fields
    if (latitude === undefined || longitude === undefined) { // Check for undefined specifically
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    // Create or update the location
    const captain = await Captain.findByIdAndUpdate(
      req.user.id,
      {
        $set: {
          // Corrected field names to match the model
          location: {
            type: 'Point',
            coordinates: [longitude, latitude], // GeoJSON format: [longitude, latitude]
            heading: heading || 0,
            speed: speed || 0,
            lastUpdated: new Date() // Use nested field
          },
          isOnline: true ,
          lastSeen: new Date()
        }
      },
      { new: true } // Return the updated document
    ).select('location isOnline'); // Select only relevant fields for response if needed

    if (!captain) {
      return res.status(404).json({ success: false, message: 'Captain not found' });
    }

    // Check if captain is on a ride and update ride with location
    const activeRide = await Ride.findOne({
      captainId: req.user.id,
      status: { $in: ['Accepted', 'Arrived','Started'] }
    }).populate('user','socketId');

    if (activeRide  && activeRide.user && activeRide.user.socketId) {
      const io = getIO();
      if(io){
        const userSocketId = activeRide.user.socketId;
      io.to(userSocketId).emit('captainLocationUpdate', {
        rideId: activeRide._id,
        location: {
          latitude: latitude,
          longitude: longitude,
          heading: heading || 0, // Send heading
          timestamp: Date.now(),
        },
      });
      logger.debug(`Emitted location update for ride ${activeRide._id} to user socket ${userSocketId}`);
      }
      }else if(activeRide){
        logger.warn(`Could not emit location update for ride ${activeRide._id}: User or user socketId missing.`);
      }

    res.status(200).json({
      success: true,
      message: 'Location updated successfully',
    });
  } catch (error) {
    logger.error('Error updating captain location:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Get captain ride history
 */
exports.getRideHistory = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const captainId = req.user.id;

    const pageNum = parseInt(page, 10);
    const limitNum = parseInt(limit, 10);
    if (isNaN(pageNum) || pageNum < 1 || isNaN(limitNum) || limitNum < 1) {
        return res.status(400).json({ success: false, message: 'Invalid pagination parameters.' });
    }

    // Create filter object
    const filter = { captainId: mongoose.Types.ObjectId(captainId) };

    const validStatuses = ['Completed', 'CancelledByUser', 'CancelledByDriver'];

    if (status && validStatuses.includes(status)) {
      filter.status = status;
    }else if (status) {
      logger.warn(`Invalid Status Filter requested in ride history: ${status}`);
    }else{
      filter.status = { $in: validStatuses };
    }

    // Get total count for pagination
    const total = await Ride.countDocuments(filter);

    // Find rides
    const rides = await Ride.find(filter)
      .populate('userId', 'firstName lastName phone profileImage')
      .sort({ createdAt: -1 })
      .skip((pageNum - 1) * limitNum)
      .limit(parseInt(limitNum));

    res.status(200).json({
      success: true,
      data: {
        rides,
        pagination: {
          total,
          page: parseInt(pageNum),
          pages: Math.ceil(total / limitNum)
        }
      }
    });
  } catch (error) {
    logger.error('Error fetching ride history:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Get captain earnings
 */
exports.getEarnings = async (req, res) => {
  try {
    const { period = 'all' } = req.query;
    const captainId = req.user.id;

    // Create date filter based on period
    let dateFilter = {};
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    switch (period) {
      case 'today':
        dateFilter = { createdAt: { $gte: startOfDay } };
        break;
      case 'week':
        const startOfWeek = new Date(startOfDay);
        startOfWeek.setDate(startOfDay.getDate() - now.getDay()); 
        dateFilter = { completedAt: { $gte: startOfWeek } };
        break;
      case 'month':
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        dateFilter = { createdAt: { $gte: startOfMonth } };
        break;
    }

    const earningsData = await Ride.aggregate([
      {
        $match: {
          captain: new mongoose.Types.ObjectId(captainId),
          status: 'Completed', // Only count completed rides
          completedAt: { $ne: null }, // Ensure completedAt exists
          ...dateFilter // Apply date filter
        }
      },
      {
        $group: {
          _id: null, // Group all matching rides together
          totalEarnings: { $sum: '$finalFare' }, // Sum the finalFare field
          totalRides: { $sum: 1 } // Count the number of rides
        }
      }
    ]);

    // Group by day for chart data
    const dailyEarningsData = await Ride.aggregate([
      {
       $match: {
         captain: new mongoose.Types.ObjectId(captainId),
         status: 'Completed',
         completedAt: { $ne: null },
         ...dateFilter
       }
     },
     {
       $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$completedAt" } }, // Group by date
          dailyTotal: { $sum: '$finalFare' },
          ridesCount: { $sum: 1 }
       }
     },
     { $sort: { _id: 1 } } // Sort by date
   ]);
   const result = earningsData.length > 0 ? earningsData[0] : { totalEarnings: 0, totalRides: 0 };

    // Convert to array for easier frontend processing
    const chartData = Object.keys(dailyEarnings).map(date => ({
      date: d._id,
      earnings: d.dailyTotal,
      rides: d.ridesCount
    }));

    res.status(200).json({
      success: true,
      data: {
        totalEarnings: result.totalEarnings,
        totalRides: result.totalRides,
        chartData,
        period
      }
    });
  } catch (error) {
    logger.error('Error fetching earnings:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Get available rides near the captain
 */
exports.getAvailableRides = async (req, res) => {
  try {
    const captainId = req.user.id;
    const maxDistanceKm = 10; // Max search radius in KM (adjust as needed, e.g., 5-10km)
    const maxDistanceMeters = maxDistanceKm * 1000;

    // 1. Get the captain's current location and availability status
    const captain = await Captain.findById(captainId).select('location isAvailable'); // Ensure isAvailable is selected
    if (!captain) { // Check if captain exists first
      return res.status(404).json({ // Changed to 404 if captain not found
        success: false,
        message: 'Captain not found.'
      });
    }
    
    if (!captain.isAvailable) { // Then check if captain is available
      return res.status(400).json({
        success: false,
        message: 'You must be available to see ride requests.'
      });
    }
    
    if (!captain.location || !captain.location.coordinates || captain.location.coordinates.length !== 2) {
      return res.status(400).json({
        success: false,
        message: 'Captain location not available. Please update your location.'
      });
    }

    const [longitude, latitude] = captain.location.coordinates;

    // 2. Find nearby rides with status 'requested'
    const availableRides = await Ride.find({
      status: 'pending', // Only find rides that haven't been accepted
      // Ensure no captain is already assigned
       pickupLocation: {
         $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude] // Captain's location [long, lat]
          },
          $maxDistance: maxDistanceMeters // Max distance in meters
        }
      }
      // Optional: Add filter to exclude rides declined by this captain
      // 'declinedBy.captainId': { $ne: captainId }
    })
    .populate('user', 'firstName lastName averageRating profileImage') // Populate user details
    .sort({ requestedAt: 1 }); // Optional: Sort by oldest request first

    if (!availableRides || availableRides.length === 0) {
        return res.status(200).json({
            success: true,
            message: 'No available rides found nearby.',
            data: []
        });
    }

    // Optional: Calculate distance for each ride (DB already filtered by maxDistance)
    // const ridesWithDistance = availableRides.map(ride => {
    //     const distance = geoUtils.calculateDistance(
    //         latitude, longitude,
    //         ride.pickupLocation.latitude, ride.pickupLocation.longitude
    //     );
    //     return { ...ride.toObject(), distance: distance.toFixed(2) }; 
    // });

    res.status(200).json({
      success: true,
      data: availableRides // Send the found rides (or ridesWithDistance)
    });

  } catch (error) {
    logger.error('Error fetching available rides:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching available rides',
      error: error.message
    });
  }
};

/**
 * Accept a ride request
 */
exports.acceptRideRequest = async (req, res) => {
  const { rideId } = req.params;
  const captainId = req.user.id; // Use authenticated captain's ID

  if (!mongoose.Types.ObjectId.isValid(rideId)) {
    return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
  }

  try {
    // Check captain's availability first
    const captain = await Captain.findById(captainId).select('isAvailable isOnline firstName lastName phone averageRating vehicleDetails profileImage location'); // Added location
    if (!captain || !captain.isAvailable || !captain.isOnline) {
        return res.status(400).json({ success: false, message: 'You must be online and available to accept rides.' });
    }

    // Use findOneAndUpdate for atomicity: find a 'Pending' ride and update it only if not already taken
    const ride = await Ride.findOneAndUpdate(
        { _id: rideId, status: 'pending' }, // Condition: Must be this ID and still Pending (assuming 'pending' is the initial state)
        {
            $set: {
                captainId: captainId, // Corrected field name
                status: 'Accepted', // Corrected status value
                acceptedAt: new Date()
            }
        },
        { new: true } // Return the updated document
    ).populate('user', 'socketId'); // Populate user to get socketId for notification

    if (!ride) {
        // If null, ride was not found OR it was already accepted by someone else
        // Check if the ride exists but has a different status
        const existingRide = await Ride.findById(rideId).select('status');
        if (existingRide && existingRide.status !== 'pending') {
             return res.status(400).json({ success: false, message: `Ride is no longer available (status: ${existingRide.status})` });
        }
        return res.status(404).json({ success: false, message: 'Ride not found or already accepted' });
    }

    // Optional: Set captain to unavailable after accepting a ride
    // await Captain.findByIdAndUpdate(captainId, { $set: { isAvailable: false } });

    // Notify the user that their ride was accepted
    const io = getIO();
    if (io && ride.user?.socketId) {
        io.to(ride.user.socketId).emit('rideAccepted', {
            rideId: ride._id,
            captainId: ride.captain, // Use correct field name
            captainDetails: { // Send relevant captain details
                _id: captain._id,
                firstName: captain.firstName,
                lastName: captain.lastName,
                phone: captain.phone,
                rating: captain.averageRating, // Use averageRating field if exists
                vehicleDetails: captain.vehicleDetails,
                profileImage: captain.profileImage,
                location: captain.location // Send current captain location
            },
            acceptedAt: ride.acceptedAt,
        });
        logger.info(`Notifying user socket ${ride.user.socketId} that ride ${ride._id} was accepted by captain ${captainId}`);
    } else {
         logger.warn(`Could not notify user for accepted ride ${ride._id}: User or user socketId not found.`);
         // This implies user model needs socketId or another way to find user's socket
    }

    // Notify other captains listening for rides that this one is taken
    if (io) {
        // Emit a general event, captains' apps should remove this ride from their available list
        io.emit('rideTaken', { rideId: ride._id });
        logger.info(`Broadcasting ride ${ride._id} is taken`);
    }

    res.status(200).json({
        success: true,
        message: 'Ride accepted successfully',
        data: ride // Return the updated ride object
    });

  } catch (error) {
    logger.error('Error accepting ride request:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
/**
 * Mark arrival at pickup (POST /api/captains/arrive)
 */
exports.markAsArrived = async (req, res) => {
    const { rideId } = req.params;
    const captainId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(rideId)) {
        return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
    }

    try {
        const ride = await Ride.findOneAndUpdate(
            { _id: rideId, captain: captainId, status: 'Accepted' }, // Condition
            { $set: { status: 'Arrived', arrivedAt: new Date() } },
            { new: true }
        ).populate('user', 'socketId');

        if (!ride) {
          const existingRide = await Ride.findById(rideId).select('status captain');
          if(!existingRide) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
          }
          if(existingRide.captain?.toString() !== captainId) {
            return res.status(403).json({ success: false, message: 'Ride not assigned to you' });
          }
          if(existingRide.status !== 'Accepted') {
            return res.status(400).json({ success: false, message: `Ride is not in Accepted status (current: ${existingRide.status})` });
          }
            return res.status(404).json({ success: false, message: 'Ride not found, not assigned to you, or not in Accepted status' });
        }

        // Notify user
        const io = getIO();
        if (io && ride.user?.socketId) {
            io.to(ride.user.socketId).emit('driverArrived', { rideId: ride._id, arrivedAt: ride.arrivedAt });
            logger.info(`Notifying user socket ${ride.user.socketId} that driver arrived for ride ${ride._id}`);
        } else {
            logger.warn(`Could not notify user of arrival for ride ${ride._id}: User or user socketId missing.`);
        }

        res.status(200).json({
            success: true,
            message: 'Marked as arrived successfully',
            data: ride
        });

    } catch (error) {
        logger.error('Error marking arrival:', error);
        res.status(500).json({ success: false, message: 'Server error while marking arrival', error: error.message });
    }
};

/**
 * Start the ride (POST /api/captains/start-ride)
 */
exports.startRide = async (req, res) => {
    const { rideId } = req.params;
    const captainId = req.user.id;

     if (!mongoose.Types.ObjectId.isValid(rideId)) {
        return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
    }

    try {
        const ride = await Ride.findOneAndUpdate(
            { _id: rideId, captain: captainId, status: 'Arrived' }, // Condition: Must be 'Arrived'
            { $set: { status: 'Started', startedAt: new Date() } },
            { new: true }
        ).populate('user', 'socketId');

        if (!ride) {
          const existingRide = await Ride.findById(rideId).select('status captain');
          if(!existingRide) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
          }
          if(existingRide.captain?.toString() !== captainId) {
            return res.status(403).json({ success: false, message: 'Ride not assigned to you' });
          }
          if(existingRide.status !== 'Arrived') {
            return res.status(400).json({ success: false, message: `Ride is not in Arrived status (current: ${existingRide.status})` });
          }
            return res.status(404).json({ success: false, message: 'Ride not found, not assigned to you, or not in Arrived status' });
        }

        // Notify user
        const io = getIO();
        if (io && ride.user?.socketId) {
            io.to(ride.user.socketId).emit('rideStarted', { rideId: ride._id, startedAt: ride.startedAt });
            logger.info(`Notifying user socket ${ride.user.socketId} that ride ${ride._id} has started`);
        } else {
             logger.warn(`Could not notify user of ride start for ride ${ride._id}: User or user socketId missing.`);
        }

        res.status(200).json({
            success: true,
            message: 'Ride started successfully',
            data: ride
        });

    } catch (error) {
        logger.error('Error starting ride:', error);
        res.status(500).json({ success: false, message: 'Server error while starting ride', error: error.message });
    }
};
/**
 * Complete a ride
 */
exports.completeRide = async (req, res) => {
  const { rideId } = req.params; // Ride ID from URL params
  const {finalFare, distance, duration } = req.body;
  const captainId = req.user.id;

  if (!mongoose.Types.ObjectId.isValid(rideId)) {
    return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
  }
  if (finalFare === undefined || isNaN(Number(finalFare))) { // Validate finalFare
    return res.status(400).json({ success: false, message: 'Valid finalFare is required' });
  }

  try {
    const ride = await Ride.findOneAndUpdate(
      { _id: rideId, captainId: captainId, status: 'Started' }, // Condition: Must be 'Started' and correct captainId field
      {
        $set: {
          status: 'Completed',
          completedAt: new Date(),
          finalFare: Number(finalFare), // Store final fare
          distance: distance,   // Store final distance if provided
          duration: duration,    // Store final duration if provided
          // paymentStatus: 'Pending' // Set payment status if applicable
        }
      },
      { new: true }
    ).populate('user', 'socketId'); // Populate user to get socketId

    if (!ride) {
      // Check why it wasn't found
      const existingRide = await Ride.findById(rideId).select('status captainId');
      if (!existingRide) {
        return res.status(404).json({ success: false, message: 'Ride not found' });
      }
      if (existingRide.captainId?.toString() !== captainId) {
         return res.status(403).json({ success: false, message: 'Ride not assigned to you' });
      }
      if (existingRide.status !== 'Started') {
         return res.status(400).json({ success: false, message: `Ride is not in Started status (current: ${existingRide.status})` });
      }
      // If none of the above, it's an unexpected state
      return res.status(404).json({ success: false, message: 'Ride not found, not assigned to you, or not in Started status' });
    }

    // Update captain's total earnings and availability
    await Captain.findByIdAndUpdate(captainId, {
      $inc: { totalEarnings: ride.finalFare || 0 }, // Increment earnings
      $set: { isAvailable: true } // Make captain available again
    });
    logger.info(`Captain ${captainId} completed ride ${rideId}. Earnings incremented by ${ride.finalFare}. Set to available.`);

    // TODO: Trigger payment processing logic here if needed

    // Notify user
    const io = getIO();
    if (io && ride.user?.socketId) {
      io.to(ride.user.socketId).emit('rideCompleted', {
        rideId: ride._id,
        completedAt: ride.completedAt,
        finalFare: ride.finalFare, // Send final details
        distance: ride.distance,
        duration: ride.duration
      });
      logger.info(`Notifying user socket ${ride.user.socketId} that ride ${ride._id} is completed`);
    } else {
      logger.warn(`Could not notify user of ride completion for ride ${ride._id}: User or user socketId missing.`);
    }

    res.status(200).json({
      success: true,
      message: 'Ride completed successfully',
      data: ride // Return the updated ride object
    });

  } catch (error) {
    logger.error('Error completing ride:', error);
    res.status(500).json({ success: false, message: 'Server error while completing ride', error: error.message });
  }
};

/**
 * Cancel a ride
 */
exports.cancelRideByDriver = async (req, res) => {
  const { rideId } = req.params; // Ride ID from URL params
  const { reason } = req.body; // Get reason from request body
  const captainId = req.user.id;

     if (!mongoose.Types.ObjectId.isValid(rideId)) {
        return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
    }

    try {
        const ride = await Ride.findOneAndUpdate(
            {
                _id: rideId,
                captainId: captainId, // Corrected field name
                status: { $in: ['Accepted', 'Arrived'] } // Can cancel if Accepted or Arrived
            },
            {
                $set: {
                    status: 'CancelledByDriver', // Use a specific status
                    cancelledAt: new Date(),
                    cancellationReason: reason || 'Cancelled by driver', // Store cancellation reason
                    cancelledBy: 'captain' // Indicate who cancelled
                }
            },
            { new: true }
        ).populate('user', 'socketId'); // Populate user for notification

        if (!ride) {
            // Check why it failed
            const existingRide = await Ride.findById(rideId).select('status captainId');
            if (!existingRide) {
                return res.status(404).json({ success: false, message: 'Ride not found' });
            }
            if (existingRide.captainId?.toString() !== captainId) {
                 return res.status(403).json({ success: false, message: 'Ride not assigned to you' });
            }
            if (!['Accepted', 'Arrived'].includes(existingRide.status)) {
                 return res.status(400).json({ success: false, message: `Ride cannot be cancelled in its current status (${existingRide.status})` });
            }
            // Default error if none of the above match
            return res.status(404).json({ success: false, message: 'Ride not found, not assigned to you, or cannot be cancelled in current status' });
        }

        // Make captain available again after cancelling
        await Captain.findByIdAndUpdate(captainId, { $set: { isAvailable: true } });
        logger.info(`Captain ${captainId} cancelled ride ${rideId}. Set to available.`);

        // Notify user
        const io = getIO();
        if (io && ride.user?.socketId) {
            io.to(ride.user.socketId).emit('rideCancelled', {
                rideId: ride._id,
                cancelledAt: ride.cancelledAt,
                reason: ride.cancellationReason,
                cancelledBy: 'captain' // Consistent with the 'cancelledBy' field
            });
            logger.info(`Notifying user socket ${ride.user.socketId} that ride ${ride._id} was cancelled by captain`);
        } else {
             logger.warn(`Could not notify user of ride cancellation for ride ${ride._id}: User or user socketId missing.`);
        }

        // Optional: Re-broadcast the ride request if it was just 'Accepted'?
        // This requires careful thought - could lead to confusion.
        // For now, just mark as cancelled.

        res.status(200).json({
            success: true,
            message: 'Ride cancelled successfully',
            data: ride // Return the updated ride object
        });

    } catch (error) {
        logger.error('Error cancelling ride by driver:', error);
        res.status(500).json({ success: false, message: 'Server error while cancelling ride', error: error.message });
    }
};

/**
 * Decline a ride request
 */
exports.declineRideRequest = async (req, res) => {
  const { rideId } = req.params; // Ride ID from URL params
  const { reason } = req.body;
  const captainId = req.user.id; // Use authenticated captain's ID
  if (!mongoose.Types.ObjectId.isValid(rideId)) {
      return res.status(400).json({ success: false, message: 'Invalid Ride ID' });
  }
  try {
    const ride = await Ride.findOneAndUpdate(
      { _id: rideId, status:'pending'},
      {$addToSet:{declineBy:captainId}},
      { new: true }
    );
    if (!ride) {
      const existingRide = await Ride.findById(rideId).select('status');
      if(!existingRide){
        return res.status(404).json({ success: false, message:'Ride not found'});
      }

      logger.info(`Captain ${captainId} attempted to decline ride ${rideId} but status is ${existingRide.status}`);
      return res.status(400).json({ success: true, message: `Ride is no longer pending , no action taken`});
    }

    logger.info(`Captain ${captainId} declined ride ${rideId}. Reason: ${reason || 'None'}`);

    await ride.save();

    res.status(200).json({
      success: true,
      message: 'Ride declined successfully'
    });
  } catch (error) {
    logger.error('Error declining ride request:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
