const User = require('../models/user/User'); // Corrected path
const Ride = require('../models/ride.model');

class RideMatchingService {
    constructor() {
        this.DEFAULT_SEARCH_RADIUS = 5000; // 5km in meters
        this.MAX_SEARCH_RADIUS = 15000; // 15km in meters
        this.RADIUS_INCREMENT = 2500; // 2.5km in meters
        this.MAX_ATTEMPTS = 4; // Maximum number of attempts to find a captain
    }

    async findNearbyCaptains(pickup, radius = this.DEFAULT_SEARCH_RADIUS) {
        try {
            const captains = await User.find({
                'role': 'CAPTAIN',
                'status': 'AVAILABLE',
                'currentLocation': {
                    $near: {
                        $geometry: {
                            type: 'Point',
                            coordinates: pickup.location.coordinates
                        },
                        $maxDistance: radius
                    }
                }
            }).select('_id name currentLocation rating vehicle');

            return captains;
        } catch (error) {
            console.error('Error finding nearby captains:', error);
            throw error;
        }
    }

    async findCaptainWithDynamicRadius(pickup) {
        let currentRadius = this.DEFAULT_SEARCH_RADIUS;
        let attempts = 0;

        while (attempts < this.MAX_ATTEMPTS) {
            const captains = await this.findNearbyCaptains(pickup, currentRadius);
            
            if (captains.length > 0) {
                return captains;
            }

            currentRadius += this.RADIUS_INCREMENT;
            if (currentRadius > this.MAX_SEARCH_RADIUS) {
                break;
            }
            attempts++;
        }

        return [];
    }

    async notifyCaptainsSequentially(ride, captains) {
        for (const captain of captains) {
            try {
                // Emit notification to captain through socket
                global.io.to(captain._id.toString()).emit('newRideRequest', {
                    rideId: ride._id,
                    pickup: ride.pickup,
                    dropoff: ride.dropoff,
                    passenger: ride.passenger
                });

                // Wait for captain response (30 seconds timeout)
                const accepted = await this.waitForCaptainResponse(captain._id, ride._id);
                if (accepted) {
                    return captain;
                }
            } catch (error) {
                console.error(`Error notifying captain ${captain._id}:`, error);
                continue;
            }
        }
        return null;
    }

    waitForCaptainResponse(captainId, rideId) {
        return new Promise((resolve) => {
            const timeout = setTimeout(() => {
                this.cleanup(captainId, rideId);
                resolve(false);
            }, 30000); // 30 seconds timeout

            const responseHandler = (data) => {
                if (data.rideId.toString() === rideId.toString()) {
                    this.cleanup(captainId, rideId, responseHandler, timeout);
                    resolve(true);
                }
            };

            global.io.to(captainId.toString()).on('acceptRide', responseHandler);
        });
    }

    cleanup(captainId, rideId, handler = null, timeout = null) {
        if (handler) {
            global.io.to(captainId.toString()).off('acceptRide', handler);
        }
        if (timeout) {
            clearTimeout(timeout);
        }
    }

    async updateRideStatus(rideId, newStatus, captainId = null) {
        try {
            const ride = await Ride.findById(rideId);
            if (!ride) {
                throw new Error('Ride not found');
            }

            if (captainId) {
                ride.captain = captainId;
            }

            await ride.updateStatus(newStatus);

            // Notify relevant parties about status change
            this.notifyRideStatusChange(ride);

            return ride;
        } catch (error) {
            console.error('Error updating ride status:', error);
            throw error;
        }
    }

    notifyRideStatusChange(ride) {
        const statusUpdate = {
            rideId: ride._id,
            status: ride.status,
            timestamp: ride.timestamps[ride.status.toLowerCase()]
        };

        // Notify passenger
        global.io.to(ride.passenger.toString()).emit('rideStatus', statusUpdate);

        // Notify captain if assigned
        if (ride.captain) {
            global.io.to(ride.captain.toString()).emit('rideStatus', statusUpdate);
        }
    }
}

module.exports = new RideMatchingService();