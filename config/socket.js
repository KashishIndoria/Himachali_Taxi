const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/user/User');
const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const locationService = require('../services/locationservices');
const rideMatchingService = require('../services/rideMatchingService'); // Ensure this is imported
const socketIo = require('socket.io');
const logger = require('../utils/logger'); // Use existing logger
const { model } = require('mongoose');

// Track online captains
const onlineCaptains = new Map();

// Track active rides
const activeRides = new Map();

let io;

exports.initSocket = (server) => {
  io = socketIO(server, {
    cors: {
      origin: '*', // In production, restrict this
      methods: ['GET', 'POST']
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);
    
    // User connects
    socket.on('userConnected', async (data) => {
      try {
        const { userId, token } = data;
        
        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.id !== userId) {
          throw new Error('Invalid user authentication');
        }
        
        // Associate socket with user
        socket.userId = userId;
        socket.userType = 'user';
        
        console.log(`User ${userId} connected`);
        
        // Join user-specific room for targeted messages
        socket.join(`user:${userId}`);
        
        // Update online status in database
        await User.findByIdAndUpdate(userId, {
          isOnline: true,
          lastSeen: new Date()
        });
        
        // Check if user has any active rides
        const activeRide = await Ride.findOne({
          userId: userId,
          status: { $in: ['requested', 'accepted'] }
        });
        
        if (activeRide) {
          socket.join(`ride:${activeRide._id}`);
          socket.emit('activeRideStatus', { ride: activeRide });
        }
      } catch (error) {
        console.error('User connection error:', error);
        socket.emit('error', { message: 'Authentication failed' });
      }
    });
    
    // Captain connects
    socket.on('driverConnected', async (data) => {
      try {
        const { driverId, token } = data;
        
        // Verify token if provided
        if (token) {
          const decoded = jwt.verify(token, process.env.JWT_SECRET);
          if (decoded.id !== driverId) {
            throw new Error('Invalid captain authentication');
          }
        }
        
        // Associate socket with captain
        socket.captainId = driverId;
        socket.userType = 'captain';
        
        console.log(`Captain ${driverId} connected`);
        
        // Join captain-specific room for targeted messages
        let io;

        // Socket.IO Authentication Middleware
        const authenticateSocket = async (socket, next) => {
          // Get token from handshake query or auth header (adjust based on client implementation)
          const token = socket.handshake.auth?.token || socket.handshake.query?.token;

          if (!token) {
            logger.warn('Socket connection attempt without token.');
            return next(new Error('Authentication error: No token provided.'));
          }

          try {
            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET); // Use your JWT secret

            // Attach user/captain info to the socket object for later use
            socket.userId = decoded.id; // Assuming JWT payload has 'id'
            socket.userRole = decoded.role; // Assuming JWT payload has 'role'

            logger.info(`Socket authenticated: User ID ${socket.userId}, Role: ${socket.userRole}, Socket ID: ${socket.id}`);
            next(); // Proceed to connection
          } catch (err) {
            logger.error('Socket authentication failed:', err.message);
            next(new Error('Authentication error: Invalid token.'));
          }
        };

        // Function to update user/captain socketId in DB
        const updateUserSocketId = async (userId, role, socketId) => {
          try {
            let model;
            if (role === 'user') {
              model = User;
            } else if (role === 'captain') { // Assuming 'captain' role exists
              model = Captain;
            } else {
              logger.warn(`Cannot update socketId for unknown role: ${role}`);
              return;
            }

            // Update the document
            await model.findByIdAndUpdate(userId, {
              $set: {
                socketId: socketId,
                isOnline: socketId ? true : false, // Set online status based on socketId presence
                lastSeen: new Date() // Update lastSeen on connect/disconnect
              }
            });
            logger.info(`Updated ${role} ${userId} with socketId: ${socketId}`);

          const updatedDoc = await model.findByIdAndUpdate(userId, updatedData);
          if(updatedDoc){
            logger.info(`Updated ${role} ${userId} with socketId: ${socketId}, isOnline: ${updatedData.$set.isOnline}`);
            if(role ==='captain' && !socketId && io){
              io.emit('captainOffline', { captainId: userId });
              logger.info(`Broadcasted captainOffline event for ${userId}`);
            }
          }else{
            logger.warn(`could not find ${role} with ID ${userId} to update socketId`);
          }
        } catch (error) {
          logger.error(`Error updating socketId for ${role} ${userId}:`, error);
        }
      };


        exports.initSocket = (server) => {
          io = socketIo(server, {
            cors: {
              origin: "*", // Configure allowed origins properly for production
              methods: ["GET", "POST"]
            }
          });

          // Apply authentication middleware to all incoming connections
          io.use(authenticateSocket);

          io.on('connection', (socket) => {
            logger.info(`Socket connected: User ID ${socket.userId}, Role: ${socket.userRole}, Socket ID: ${socket.id}`);

            // Update DB with the new socketId
            updateUserSocketId(socket.userId, socket.userRole, socket.id);

            // --- Join Rooms (Optional but Recommended) ---
            // Have clients join rooms based on their ID for targeted messaging
            socket.join(socket.userId); // Join a room named after their user/captain ID
            logger.info(`Socket ${socket.id} joined room: ${socket.userId}`);

            // --- Handle Custom Events ---
            // Example: Listen for a custom event from client
            socket.on('clientEventExample', (data) => {
              logger.info(`Received clientEventExample from ${socket.userId}: `, data);
              // Process data and maybe emit back or to others
              // io.to(socket.userId).emit('serverResponse', { message: 'Received your event!' });
            });


            // --- Handle Disconnect ---
            socket.on('disconnect', (reason) => {
              logger.info(`Socket disconnected: User ID ${socket.userId}, Socket ID: ${socket.id}, Reason: ${reason}`);
              // Clear socketId from DB on disconnect
              updateUserSocketId(socket.userId, socket.userRole, null);
            });

            // --- Handle Connection Errors ---
            socket.on('error', (error) => {
               logger.error(`Socket Error for User ID ${socket.userId}, Socket ID: ${socket.id}:`, error);
               // Optionally clear socketId on error too, depending on error type
               // updateUserSocketId(socket.userId, socket.userRole, null);
            });

            // TODO: Add back specific event handlers for your application logic
            // e.g., 'updateCaptainLocation', 'requestRide', 'acceptRide', etc.
            // These handlers should now use socket.userId and socket.userRole
            // Example:
            // socket.on('updateCaptainLocation', (data) => {
            //     if (socket.userRole !== 'captain') return; // Basic authorization
            //     // Process location update for socket.userId (captainId)
            // });

          });

          logger.info('Socket.IO initialized');
          return io;
        };

        // Function to get the initialized IO instance
        exports.getIO = () => {
          if (!io) {
            throw new Error('Socket.io not initialized!');
          }
          return io;
        };
        
        // Add to online captains map
        onlineCaptains.set(driverId, {
          socketId: socket.id,
          location: null,
          isAvailable: false,
          lastActivity: new Date()
        });
        
        // Update online status in database
        await Captain.findByIdAndUpdate(driverId, {
          isOnline: true,
          lastSeen: new Date()
        });
        
        // Check if captain has any active rides
        const activeRide = await Ride.findOne({
          captainId: driverId,
          status: { $in: ['accepted'] }
        });
        
        if (activeRide) {
          socket.join(`ride:${activeRide._id}`);
          socket.emit('activeRideStatus', { ride: activeRide });
        }
      } catch (error) {
        console.error('Captain connection error:', error);
        socket.emit('error', { message: 'Authentication failed' });
      }
    });

    // Captain availability status update
    socket.on('updateCaptainAvailability', async (data) => { // Using 'updateCaptainAvailability' consistently
      try {
        const { captainId, isAvailable } = data;
        if (!captainId) {
            console.error('Availability update error: captainId missing');
            socket.emit('error', { message: 'Captain ID is required for availability update.' });
            return;
        }
        // Verify socket association if possible (e.g., during initial connection)
        // if (socket.userType === 'captain' && socket.captainId !== captainId) {
        //   console.error(`Socket ${socket.id} (Captain ${socket.captainId}) attempted to update availability for ${captainId}`);
        //   socket.emit('error', { message: 'Authorization error.' });
        //   return;
        // }

        console.log(`Captain ${captainId} is now ${isAvailable ? 'available' : 'unavailable'}`);

        // Update in memory
        if (onlineCaptains.has(captainId)) {
          const captainInfo = onlineCaptains.get(captainId);
          captainInfo.isAvailable = isAvailable;
          captainInfo.lastActivity = new Date();
          onlineCaptains.set(captainId, captainInfo);
        } else {
           // Optionally add the captain if they weren't tracked but are sending updates
           console.warn(`Captain ${captainId} sent availability update but was not in onlineCaptains map.`);
           // Consider fetching captain data and adding them here if needed
        }
        // Note: The provided refactoring suggests removing this event handler ('updateCaptainAvailability')
        // and handling such updates via HTTP requests + controller logic that uses getIO().
        // If keeping this handler temporarily, ensure consistency with DB updates.
        // logger.info(`Updated captain ${captainId} availability in memory: ${isAvailable}`); // Example logging
        // Update database status
        await Captain.findByIdAndUpdate(captainId, { isAvailable: isAvailable, lastActive: new Date() });

        // Respond with confirmation (optional, but good practice)
        socket.emit('availabilityUpdated', { isAvailable });

        // Broadcast to all clients (e.g., users looking for rides)
        io.emit('captainAvailabilityChanged', {
          captainId,
          isAvailable
        });
      } catch (error) {
        console.error('Error handling availability update:', error);
        socket.emit('error', { message: 'Failed to update availability.' });
      }
    });

    // Location updates from captain
    socket.on('updateCaptainLocation', async (data) => {
      try {
        const { captainId, latitude, longitude, heading, speed } = data;

        if (!captainId || latitude === undefined || longitude === undefined) {
          console.error('Location update error: Missing required data', data);
          socket.emit('error', { message: 'Missing required fields for location update (captainId, latitude, longitude).' });
          return;
        }

        // Verify socket association if possible
        // if (socket.userType === 'captain' && socket.captainId !== captainId) {
        //   console.error(`Socket ${socket.id} (Captain ${socket.captainId}) attempted to update location for ${captainId}`);
        //   socket.emit('error', { message: 'Authorization error.' });
        //   return;
        // }

        const locationData = {
          type: 'Point',
          coordinates: [longitude, latitude], // Ensure order [longitude, latitude]
          heading: heading !== undefined ? heading : 0,
          speed: speed !== undefined ? speed : 0,
          lastUpdated: new Date()
        };

        // Update in memory
        if (onlineCaptains.has(captainId)) {
          const captainInfo = onlineCaptains.get(captainId);
          captainInfo.location = locationData;
          captainInfo.lastActivity = new Date();
          onlineCaptains.set(captainId, captainInfo);
        } else {
          console.warn(`Captain ${captainId} sent location update but was not in onlineCaptains map.`);
           // Consider fetching captain data and adding them here if needed
        }

        // Update database
        await Captain.findByIdAndUpdate(captainId, {
             location: locationData,
             lastActive: new Date()
        });

        // console.log(`Captain ${captainId} location updated: ${latitude}, ${longitude}`); // Optional: Log successful update

        // Broadcast location update to relevant clients (e.g., users viewing the map)
        // This could be broad or targeted based on proximity in a more advanced setup
        io.emit('captainLocationUpdate', { // Consider a more specific room/namespace later
            captainId,
            location: locationData
        });

      } catch (error) {
        console.error('Error handling location update:', error);
        socket.emit('error', { message: 'Failed to update location.' });
      }
    });

    // Remove or comment out the old 'updateLocation' and 'driverAvailability' handlers if they exist and are now redundant
    // socket.on('updateLocation', ...); // Remove or comment out
    // socket.on('driverAvailability', ...); // Remove or comment out

    // Rider requests a ride
    socket.on('requestRide', async (data) => {
      try {
        const { userId, pickupLocation, dropLocation, paymentMethod } = data;
        
        if (!userId || !pickupLocation || !dropLocation) {
          throw new Error('Missing required ride information');
        }
        
        // Create a new ride request
        const ride = new Ride({
          userId,
          pickupLocation,
          dropLocation,
          status: 'requested',
          fare: data.fare || 0, // Calculate fare or use provided
          paymentMethod: paymentMethod || 'cash'
        });
        
        await ride.save();
        console.log(`New ride request created: ${ride._id}`);
        
        // Find available captains nearby
        const nearbyDrivers = await rideMatchingService.findNearbyDrivers(
          pickupLocation.latitude, 
          pickupLocation.longitude
        );
        
        if (nearbyDrivers.length > 0) {
          // Send ride request to nearby captains
          for (const driver of nearbyDrivers) {
            io.to(`captain:${driver._id}`).emit('newRideRequest', {
              _id: ride._id,
              pickupLocation: ride.pickupLocation,
              dropLocation: ride.dropLocation,
              passengerName: ride.userId.firstName,
              passengerPhone: ride.userId.phone,
              passengerRating: 5.0, // Example rating
              estimatedFare: ride.fare,
              pickupAddress: pickupLocation.address,
              dropoffAddress: dropLocation.address,
              estimatedDistance: data.estimatedDistance || 0,
              estimatedDuration: data.estimatedDuration || 0,
              requestTime: ride.createdAt,
              status: 'new',
              paymentMethod: ride.paymentMethod
            });
          }
          
          // Notify user that drivers are being searched
          io.to(`user:${userId}`).emit('rideStatus', {
            status: 'searching',
            rideId: ride._id,
            message: 'Looking for nearby drivers'
          });
        } else {
          // No drivers available
          io.to(`user:${userId}`).emit('rideStatus', {
            status: 'noDrivers',
            rideId: ride._id,
            message: 'No drivers available nearby'
          });
          
          // Mark ride as cancelled due to no drivers
          ride.status = 'cancelled';
          ride.cancellationReason = 'No drivers available';
          await ride.save();
        }
      } catch (error) {
        console.error('Ride request error:', error);
        socket.emit('error', { message: error.message });
      }
    });

    // Captain accepts a ride
    socket.on('acceptRide', async (data) => {
      try {
        const { captainId, requestId } = data;
        
        // Validate the data
        if (!captainId || !requestId) {
          throw new Error('Missing required information');
        }
        
        // Find the ride
        const ride = await Ride.findById(requestId);
        if (!ride) {
          throw new Error('Ride not found');
        }
        
        // Ensure ride is still in requested status
        if (ride.status !== 'requested') {
          throw new Error('Ride already accepted or cancelled');
        }
        
        // Update ride with captain info
        ride.captainId = captainId;
        ride.status = 'accepted';
        ride.updatedAt = new Date();
        await ride.save();
        
        console.log(`Ride ${requestId} accepted by Captain ${captainId}`);
        
        // Notify the user
        io.to(`user:${ride.userId}`).emit('rideAccepted', {
          rideId: ride._id,
          captainId: captainId,
          captainName: socket.captainName || 'Your Driver', // Should get from DB
          captainPhone: socket.captainPhone || '1234567890', // Should get from DB
          captainRating: 4.5, // Example rating
          vehicleDetails: { model: 'Toyota Innova', color: 'White', plateNumber: 'HP-01-1234' }, // Example
        });
        
        // Confirm to the captain
        io.to(`captain:${captainId}`).emit('rideAccepted', {
          requestId: ride._id,
          status: 'accepted'
        });
        
        // Join both to the ride room
        socket.join(`ride:${ride._id}`);
        const userSocket = Array.from(io.sockets.sockets.values()).find(s => s.userId === ride.userId);
        if (userSocket) {
          userSocket.join(`ride:${ride._id}`);
        }
      } catch (error) {
        console.error('Ride acceptance error:', error);
        socket.emit('error', { message: error.message });
      }
    });

    // Ride cancellation by user
    socket.on('cancelRideUser', async (data) => {
      try {
        const { userId, rideId, reason } = data;
        
        // Find the ride
        const ride = await Ride.findById(rideId);
        if (!ride) {
          throw new Error('Ride not found');
        }
        
        // Ensure this is the user's ride
        if (ride.userId.toString() !== userId) {
          throw new Error('Unauthorized to cancel this ride');
        }
        
        // Update ride status
        ride.status = 'cancelled';
        ride.cancellationReason = reason || 'Cancelled by user';
        ride.updatedAt = new Date();
        await ride.save();
        
        console.log(`Ride ${rideId} cancelled by User ${userId}`);
        
        // Notify the captain if assigned
        if (ride.captainId) {
          io.to(`captain:${ride.captainId}`).emit('rideCancelled', {
            requestId: ride._id,
            reason: ride.cancellationReason
          });
        }
        
        // Confirm to the user
        io.to(`user:${userId}`).emit('rideCancelled', {
          rideId: ride._id,
          status: 'cancelled'
        });
      } catch (error) {
        console.error('Ride cancellation error:', error);
        socket.emit('error', { message: error.message });
      }
    });

    // Ride cancellation by captain
    socket.on('cancelRide', async (data) => {
      try {
        const { captainId, requestId, reason } = data;
        
        // Find the ride
        const ride = await Ride.findById(requestId);
        if (!ride) {
          throw new Error('Ride not found');
        }
        
        // Ensure this is the captain's ride
        if (ride.captainId.toString() !== captainId) {
          throw new Error('Unauthorized to cancel this ride');
        }
        
        // Update ride status
        ride.status = 'cancelled';
        ride.cancellationReason = reason || 'Cancelled by captain';
        ride.updatedAt = new Date();
        await ride.save();
        
        console.log(`Ride ${requestId} cancelled by Captain ${captainId}`);
        
        // Notify the user
        io.to(`user:${ride.userId}`).emit('rideCancelled', {
          rideId: ride._id,
          reason: ride.cancellationReason
        });
        
        // Confirm to the captain
        io.to(`captain:${captainId}`).emit('rideCancelled', {
          requestId: ride._id,
          status: 'cancelled'
        });
      } catch (error) {
        console.error('Ride cancellation error:', error);
        socket.emit('error', { message: error.message });
      }
    });

    // Complete ride
    socket.on('completeRide', async (data) => {
      try {
        const { captainId, requestId } = data;
        
        // Find the ride
        const ride = await Ride.findById(requestId);
        if (!ride) {
          throw new Error('Ride not found');
        }
        
        // Ensure this is the captain's ride
        if (ride.captainId.toString() !== captainId) {
          throw new Error('Unauthorized to complete this ride');
        }
        
        // Update ride status
        ride.status = 'completed';
        ride.updatedAt = new Date();
        await ride.save();
        
        console.log(`Ride ${requestId} completed by Captain ${captainId}`);
        
        // Notify the user
        io.to(`user:${ride.userId}`).emit('rideCompleted', {
          rideId: ride._id,
          fare: ride.fare,
          captainId: captainId
        });
        
        // Confirm to the captain
        io.to(`captain:${captainId}`).emit('rideCompleted', {
          requestId: ride._id,
          status: 'completed',
          fare: ride.fare
        });
      } catch (error) {
        console.error('Ride completion error:', error);
        socket.emit('error', { message: error.message });
      }
    });

    // Disconnect handler
    socket.on('disconnect', async () => {
      try {
        console.log('Client disconnected:', socket.id);
        let disconnectedUserId = null;
        let disconnectedUserType = null;

        if (socket.userType === 'captain' && socket.captainId) {
          disconnectedUserId = socket.captainId;
          disconnectedUserType = 'captain';
          // Remove captain from online map
          onlineCaptains.delete(disconnectedUserId);
          console.log(`Captain ${disconnectedUserId} removed from online map.`);
          // Update captain status in DB
          await Captain.findByIdAndUpdate(disconnectedUserId, { isOnline: false, isAvailable: false, socketId: null });
          // Broadcast that captain went offline
           io.emit('captainOffline', { captainId: disconnectedUserId });

        } else if (socket.userType === 'user' && socket.userId) {
          disconnectedUserId = socket.userId;
          disconnectedUserType = 'user';
           // Update user status in DB
           await User.findByIdAndUpdate(disconnectedUserId, { isOnline: false, socketId: null });
           console.log(`User ${disconnectedUserId} marked as offline.`);
        }

        // Add any cleanup logic for active rides if needed

      } catch (error) {
        console.error('Error during disconnect:', error);
      }
    });
  });

  // Run periodic cleanup of inactive clients (every minute)
  setInterval(async () => {
    try {
      const now = new Date();
      
      // Clean up inactive captains (inactive for more than 5 minutes)
      for (const [captainId, info] of onlineCaptains.entries()) {
        const timeDiff = now - info.lastActivity;
        if (timeDiff > 5 * 60 * 1000) { // 5 minutes in milliseconds
          console.log(`Removing inactive captain: ${captainId}`);
          onlineCaptains.delete(captainId);
          
          // Update database
          await Captain.findByIdAndUpdate(captainId, {
            isOnline: false,
            lastSeen: info.lastActivity
          });
        }
      }
    } catch (error) {
      console.error('Cleanup error:', error);
    }
  }, 60 * 1000); // Run every minute
  
  return io;
};

exports.getIO = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};
