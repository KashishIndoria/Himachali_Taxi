const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const { getIO } = require('../config/socket');
const logger = require('../utils/logger');

class RideMatchingService {
    constructor() {
        this.SEARCH_RADIUS = 5000; // 5km in meters
        this.MAX_SEARCH_TIME = 180000; // 3 minutes in milliseconds
        this.MIN_CAPTAIN_RATING = 4.0;
        this.activeMatches = new Map();
    }

    async findNearbyCaptains(latitude, longitude, radius = this.SEARCH_RADIUS) {
        try {
            const captains = await Captain.find({
                isOnline: true,
                isAvailable: true,
                'location.coordinates': {
                    $nearSphere: {
                        $geometry: {
                            type: 'Point',
                            coordinates: [longitude, latitude]
                        },
                        $maxDistance: radius
                    }
                },
                rating: { $gte: this.MIN_CAPTAIN_RATING }
            }).select('_id name phone vehicleDetails location rating currentRide');

            logger.info(`Found ${captains.length} nearby available captains`);
            return captains;
        } catch (error) {
            logger.error('Error finding nearby captains:', error);
            throw error;
        }
    }

    async startRideMatching(ride) {
        try {
            logger.info(`Starting ride matching for ride ${ride._id}`);
            
            // Find nearby available captains
            const captains = await this.findNearbyCaptains(ride.pickupLocation.coordinates[1], ride.pickupLocation.coordinates[0]);
            logger.info(`Found ${captains.length} nearby captains for ride ${ride._id}`);

            if (captains.length === 0) {
                logger.warn(`No nearby captains found for ride ${ride._id}`);
                return { success: false, message: 'No nearby captains available' };
            }

            // Notify captains sequentially
            const result = await this.notifyCaptainsSequentially(ride, captains);
            
            if (result) {
                logger.info(`Ride ${ride._id} matched with captain ${result._id}`);
                return { success: true, captain: result };
            } else {
                logger.warn(`No captain accepted ride ${ride._id}`);
                return { success: false, message: 'No captain accepted the ride' };
            }
        } catch (error) {
            logger.error(`Error in ride matching for ride ${ride._id}:`, error);
            throw error;
        }
    }

    async notifyCaptainsSequentially(ride, captains) {
        for (const captain of captains) {
            try {
                logger.info(`Notifying captain ${captain._id} about ride ${ride._id}`);
                
                // Emit notification to captain through socket
                getIO().to(`captain:${captain._id}`).emit('newRideRequest', {
                    rideId: ride._id,
                    pickup: ride.pickupLocation,
                    dropoff: ride.dropLocation,
                    fare: ride.fare,
                    distance: ride.distance,
                    estimatedTime: ride.estimatedTime,
                    expiresIn: 30 // seconds to respond
                });

                // Wait for captain response (30 seconds timeout)
                const accepted = await this.waitForCaptainResponse(captain._id, ride._id);
                if (accepted) {
                    logger.info(`Captain ${captain._id} accepted ride ${ride._id}`);
                    return captain;
                }
            } catch (error) {
                logger.error(`Error notifying captain ${captain._id}:`, error);
                continue;
            }
        }
        return null;
    }

    async waitForCaptainResponse(captainId, rideId) {
        return new Promise((resolve) => {
            const timeout = setTimeout(() => {
                logger.info(`Timeout waiting for captain ${captainId} response for ride ${rideId}`);
                resolve(false);
            }, 30000);

            const handler = async (data) => {
                if (data.rideId === rideId) {
                    clearTimeout(timeout);
                    getIO().off(`captain:${captainId}:rideResponse`, handler);
                    
                    if (data.accepted) {
                        try {
                            await this.acceptRide(rideId, captainId);
                            resolve(true);
                        } catch (error) {
                            logger.error(`Error accepting ride ${rideId} by captain ${captainId}:`, error);
                            resolve(false);
                        }
                    } else {
                        logger.info(`Captain ${captainId} declined ride ${rideId}`);
                        resolve(false);
                    }
                }
            };

            getIO().on(`captain:${captainId}:rideResponse`, handler);
        });
    }

    async handleNoMatchFound(ride) {
        const io = getIO();
        await Ride.findByIdAndUpdate(ride._id, {
            status: 'cancelled',
            cancellationReason: 'No captains available'
        });

        io.to(`user:${ride.userId}`).emit('rideStatus', {
            status: 'cancelled',
            message: 'No captains available at the moment'
        });
    }

    async acceptRide(rideId, captainId) {
        try {
            const ride = await Ride.findById(rideId);
            const captain = await Captain.findById(captainId);

            if (!ride || !captain) {
                throw new Error('Ride or Captain not found');
            }

            if (ride.status !== 'searching') {
                throw new Error('Ride is no longer available');
            }

            // Update ride status
            ride.status = 'accepted';
            ride.captainId = captainId;
            await ride.save();

            // Update captain status
            captain.isAvailable = false;
            captain.currentRide = rideId;
            await captain.save();

            const io = getIO();

            // Notify user
            io.to(`user:${ride.userId}`).emit('rideAccepted', {
                rideId: ride._id,
                captain: {
                    id: captain._id,
                    name: captain.name,
                    phone: captain.phone,
                    vehicleDetails: captain.vehicleDetails,
                    location: captain.location,
                    rating: captain.rating
                }
            });

            return ride;
        } catch (error) {
            logger.error('Error accepting ride:', error);
            throw error;
        }
    }
}

module.exports = new RideMatchingService();
