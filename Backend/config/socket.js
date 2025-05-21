const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/user/User');
const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const locationService = require('../services/locationservices');
const rideMatchingService = require('../services/rideMatchingService');
const locationFallbackService = require('../services/locationFallbackService');
const socketIo = require('socket.io');
const logger = require('../utils/logger');
const { model } = require('mongoose');
const { WEBRTC_CONFIG, VIDEO_CALL_TIMEOUT } = require('./video.config');

// Track online captains and their locations
const onlineCaptains = new Map();

// Track active rides
const activeRides = new Map();

// Rate limiting configuration
const RATE_LIMIT = {
    locationUpdate: {
        maxRequests: 10, // Maximum requests per interval
        interval: 10000, // 10 seconds
    }
};

// Track rate limits per socket
const rateLimits = new Map();

let io;

const initSocket = (server) => {
    io = socketIO(server, {
        cors: {
            origin: process.env.FRONTEND_URL || "http://localhost:3000",
            methods: ["GET", "POST"]
        }
    });

    // Authentication middleware
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth.token;
            if (!token) {
                return next(new Error('Authentication error'));
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.userId = decoded.id;
            socket.userType = decoded.type; // 'user' or 'captain'
            next();
        } catch (error) {
            next(new Error('Authentication error'));
        }
    });

    io.on('connection', (socket) => {
        console.log(`${socket.userType} connected:`, socket.userId);

        // Initialize rate limit tracking for this socket
        rateLimits.set(socket.id, {
            locationUpdate: {
                count: 0,
                lastReset: Date.now()
            }
        });

        // Join user-specific room
        socket.join(`${socket.userType}:${socket.userId}`);

        // Handle captain coming online
        if (socket.userType === 'captain') {
            socket.on('goOnline', async (location) => {
                try {
                    await Captain.findByIdAndUpdate(socket.userId, {
                        isOnline: true,
                        isAvailable: true,
                        location: {
                            type: 'Point',
                            coordinates: [location.longitude, location.latitude]
                        }
                    });

                    onlineCaptains.set(socket.userId, {
                        socketId: socket.id,
                        location: location,
                        lastUpdate: new Date()
                    });

                    socket.emit('onlineStatus', { status: 'online' });
                } catch (error) {
                    socket.emit('error', { message: 'Failed to go online' });
                }
            });

            // Handle captain location updates with rate limiting
            socket.on('updateLocation', async (data) => {
                try {
                    // Check rate limit
                    const rateLimit = rateLimits.get(socket.id).locationUpdate;
                    const now = Date.now();
                    
                    // Reset counter if interval has passed
                    if (now - rateLimit.lastReset > RATE_LIMIT.locationUpdate.interval) {
                        rateLimit.count = 0;
                        rateLimit.lastReset = now;
                    }

                    // Check if rate limit exceeded
                    if (rateLimit.count >= RATE_LIMIT.locationUpdate.maxRequests) {
                        socket.emit('error', { 
                            message: 'Location update rate limit exceeded. Please wait.',
                            code: 'RATE_LIMIT_EXCEEDED'
                        });
                        return;
                    }

                    // Validate location data
                    if (!isValidLocation(data)) {
                        socket.emit('error', {
                            message: 'Invalid location data',
                            code: 'INVALID_LOCATION'
                        });
                        return;
                    }

                    const { latitude, longitude } = data;
                    const location = {
                        type: 'Point',
                        coordinates: [longitude, latitude]
                    };

                    // Update captain's location in database
                    await Captain.findByIdAndUpdate(socket.userId, { location });

                    // If captain is in a ride, notify passenger
                    const captain = await Captain.findById(socket.userId);
                    if (captain?.currentRide) {
                        const ride = await Ride.findById(captain.currentRide);
                        if (ride && ['accepted', 'started'].includes(ride.status)) {
                            try {
                                // Update ride location
                                ride.currentLocation = location;
                                await ride.save();

                                // Emit location update to user
                                io.to(`user:${ride.userId}`).emit('captainLocation', {
                                    rideId: ride._id,
                                    location: location,
                                    timestamp: now
                                });
                            } catch (error) {
                                // If real-time update fails, add to fallback queue
                                logger.error('Failed to update ride location in real-time:', error);
                                await locationFallbackService.handleFailedUpdate(ride._id, location);
                            }
                        }
                    }

                    // Update rate limit counter
                    rateLimit.count++;

                } catch (error) {
                    logger.error('Error updating location:', error);
                    socket.emit('error', {
                        message: 'Failed to update location',
                        code: 'UPDATE_FAILED'
                    });

                    // If captain is in a ride, add to fallback queue
                    const captain = await Captain.findById(socket.userId);
                    if (captain?.currentRide) {
                        await locationFallbackService.handleFailedUpdate(
                            captain.currentRide,
                            {
                                type: 'Point',
                                coordinates: [data.longitude, data.latitude]
                            }
                        );
                    }
                }
            });
        }

        // Handle ride requests from users
        if (socket.userType === 'user') {
            socket.on('requestRide', async (data) => {
                try {
                    const { pickupLocation, dropLocation } = data;
                    
                    const ride = new Ride({
                        userId: socket.userId,
                        pickupLocation: {
                            type: 'Point',
                            coordinates: [pickupLocation.longitude, pickupLocation.latitude],
                            address: pickupLocation.address
                        },
                        dropLocation: {
                            type: 'Point',
                            coordinates: [dropLocation.longitude, dropLocation.latitude],
                            address: dropLocation.address
                        },
                        status: 'requested',
                        distance: data.distance,
                        estimatedTime: data.estimatedTime
                    });

                    await ride.calculateFare();
                    await ride.save();

                    // Start matching process
                    rideMatchingService.startRideMatching(ride);

                    socket.emit('rideStatus', {
                        status: 'requested',
                        rideId: ride._id,
                        message: 'Looking for nearby captains'
                    });
                } catch (error) {
                    socket.emit('error', { message: 'Failed to request ride' });
                }
            });
        }

        // Handle video call signaling
        socket.on('call-user', ({ targetUserId, offer, rideId }) => {
            const timeout = setTimeout(() => {
                io.to(`user:${targetUserId}`).emit('call-missed', {
                    from: socket.userId
                });
                socket.emit('call-timeout');
            }, VIDEO_CALL_TIMEOUT);

            socket.timeout = timeout;
            
            io.to(`user:${targetUserId}`).emit('incoming-call', {
                from: socket.userId,
                offer,
                rideId
            });
        });

        socket.on('call-accepted', ({ targetUserId, answer }) => {
            if (socket.timeout) {
                clearTimeout(socket.timeout);
            }
            
            io.to(`user:${targetUserId}`).emit('call-accepted', {
                from: socket.userId,
                answer
            });
        });

        socket.on('call-rejected', ({ targetUserId }) => {
            if (socket.timeout) {
                clearTimeout(socket.timeout);
            }
            
            io.to(`user:${targetUserId}`).emit('call-rejected', {
                from: socket.userId
            });
        });

        socket.on('ice-candidate', ({ targetUserId, candidate }) => {
            io.to(`user:${targetUserId}`).emit('ice-candidate', {
                from: socket.userId,
                candidate
            });
        });

        socket.on('end-call', ({ targetUserId }) => {
            io.to(`user:${targetUserId}`).emit('call-ended', {
                from: socket.userId
            });
        });

        // Handle ride status updates
        socket.on('updateRideStatus', async (data) => {
            try {
                const { rideId, status, location } = data;
                const ride = await Ride.findById(rideId);

                if (!ride) {
                    throw new Error('Ride not found');
                }

                // Verify authorization
                if (socket.userType === 'captain' && ride.captainId.toString() !== socket.userId) {
                    throw new Error('Unauthorized');
                }

                await ride.updateStatus(status, location);

                // Notify both parties
                io.to(`user:${ride.userId}`).to(`captain:${ride.captainId}`).emit('rideStatusUpdated', {
                    rideId: ride._id,
                    status: ride.status,
                    location: location
                });

                // Handle ride completion
                if (status === 'completed') {
                    const captain = await Captain.findById(ride.captainId);
                    captain.isAvailable = true;
                    captain.currentRide = null;
                    await captain.save();
                }
            } catch (error) {
                socket.emit('error', { message: 'Failed to update ride status' });
            }
        });

        // Handle reconnection
        socket.on('reconnect_attempt', () => {
            logger.info(`Reconnection attempt by ${socket.userType}:${socket.userId}`);
        });

        socket.on('reconnect', () => {
            logger.info(`Reconnected: ${socket.userType}:${socket.userId}`);
            // Rejoin rooms and restore state
            socket.join(`${socket.userType}:${socket.userId}`);
            if (socket.userType === 'captain') {
                socket.join('captains');
            }
        });

        // Handle disconnection
        socket.on('disconnect', async () => {
            if (socket.timeout) {
                clearTimeout(socket.timeout);
            }

            // Clean up rate limit tracking
            rateLimits.delete(socket.id);

            if (socket.userType === 'captain') {
                try {
                    await Captain.findByIdAndUpdate(socket.userId, {
                        isOnline: false,
                        isAvailable: false
                    });
                    onlineCaptains.delete(socket.userId);
                } catch (error) {
                    logger.error('Error updating captain status on disconnect:', error);
                }
            }

            logger.info(`${socket.userType} disconnected:`, socket.userId);
        });
    });

    return io;
};

// Helper function to validate location data
function isValidLocation(data) {
    if (!data || typeof data !== 'object') return false;
    
    const { latitude, longitude } = data;
    
    // Check if coordinates exist and are numbers
    if (typeof latitude !== 'number' || typeof longitude !== 'number') return false;
    
    // Check if coordinates are within valid ranges
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    
    return true;
}

module.exports = {
    initSocket,
    getIO: () => {
        if (!io) {
            throw new Error('Socket.io not initialized');
        }
        return io;
    }
};
