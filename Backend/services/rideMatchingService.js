const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const { getIO } = require('../config/socket');

class RideMatchingService {
    constructor() {
        this.SEARCH_RADIUS = 5000; // 5km in meters
        this.MAX_SEARCH_TIME = 180000; // 3 minutes in milliseconds
        this.MIN_CAPTAIN_RATING = 4.0;
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

            return captains;
        } catch (error) {
            console.error('Error finding nearby captains:', error);
            throw error;
        }
    }

    async startRideMatching(ride) {
        const io = getIO();
        let searchRadius = this.SEARCH_RADIUS;
        let startTime = Date.now();
        let matchFound = false;

        const searchInterval = setInterval(async () => {
            try {
                if (Date.now() - startTime > this.MAX_SEARCH_TIME) {
                    clearInterval(searchInterval);
                    await this.handleNoMatchFound(ride);
                    return;
                }

                const nearbyCaptains = await this.findNearbyCaptains(
                    ride.pickupLocation.coordinates[1],
                    ride.pickupLocation.coordinates[0],
                    searchRadius
                );

                if (nearbyCaptains.length > 0) {
                    matchFound = true;
                    clearInterval(searchInterval);
                    await this.notifyCaptains(nearbyCaptains, ride);
                } else {
                    // Increase search radius by 1km each iteration
                    searchRadius += 1000;
                }
            } catch (error) {
                console.error('Error in ride matching:', error);
                clearInterval(searchInterval);
                await this.handleNoMatchFound(ride);
            }
        }, 10000); // Check every 10 seconds
    }

    async notifyCaptains(captains, ride) {
        const io = getIO();
        const rideDetails = {
            rideId: ride._id,
            pickupLocation: ride.pickupLocation,
            dropLocation: ride.dropLocation,
            fare: ride.fare,
            distance: ride.distance,
            estimatedTime: ride.estimatedTime
        };

        // Update ride status to searching
        await Ride.findByIdAndUpdate(ride._id, { status: 'searching' });

        // Notify user that we're finding a captain
        io.to(`user:${ride.userId}`).emit('rideStatus', {
            status: 'searching',
            message: 'Looking for nearby captains'
        });

        // Notify each captain in sequence with a delay
        for (const captain of captains) {
            io.to(`captain:${captain._id}`).emit('newRideRequest', {
                ...rideDetails,
                expiresIn: 30 // seconds to respond
            });

            // Wait for 30 seconds before trying next captain
            await new Promise(resolve => setTimeout(resolve, 30000));

            // Check if ride was accepted
            const updatedRide = await Ride.findById(ride._id);
            if (updatedRide.status === 'accepted') {
                break;
            }
        }
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
            console.error('Error accepting ride:', error);
            throw error;
        }
    }
}

module.exports = new RideMatchingService();
