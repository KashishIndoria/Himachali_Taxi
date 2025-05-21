const Ride = require('../models/rides/rides');
const Captain = require('../models/captain/captain');
const logger = require('../utils/logger');

class LocationFallbackService {
    constructor() {
        this.fallbackQueue = new Map(); // Map of rideId to location updates
        this.processingInterval = null;
        this.FALLBACK_INTERVAL = 5000; // 5 seconds
        this.MAX_RETRIES = 3;
    }

    start() {
        if (this.processingInterval) return;
        
        this.processingInterval = setInterval(() => {
            this.processFallbackQueue();
        }, this.FALLBACK_INTERVAL);
    }

    stop() {
        if (this.processingInterval) {
            clearInterval(this.processingInterval);
            this.processingInterval = null;
        }
    }

    async addToFallbackQueue(rideId, location, retryCount = 0) {
        if (!this.fallbackQueue.has(rideId)) {
            this.fallbackQueue.set(rideId, []);
        }

        const queue = this.fallbackQueue.get(rideId);
        queue.push({
            location,
            timestamp: Date.now(),
            retryCount
        });

        // Keep only the latest 10 updates per ride
        if (queue.length > 10) {
            queue.shift();
        }
    }

    async processFallbackQueue() {
        for (const [rideId, updates] of this.fallbackQueue.entries()) {
            try {
                const ride = await Ride.findById(rideId);
                if (!ride) {
                    this.fallbackQueue.delete(rideId);
                    continue;
                }

                // Process each update in the queue
                for (const update of updates) {
                    if (update.retryCount >= this.MAX_RETRIES) {
                        logger.warn(`Max retries reached for ride ${rideId}, dropping update`);
                        continue;
                    }

                    try {
                        // Update ride location
                        ride.currentLocation = update.location;
                        await ride.save();

                        // Update captain location
                        const captain = await Captain.findById(ride.captainId);
                        if (captain) {
                            captain.location = update.location;
                            await captain.save();
                        }

                        // Remove processed update
                        updates.splice(updates.indexOf(update), 1);
                    } catch (error) {
                        logger.error(`Error processing fallback update for ride ${rideId}:`, error);
                        update.retryCount++;
                    }
                }

                // Remove ride from queue if all updates processed
                if (updates.length === 0) {
                    this.fallbackQueue.delete(rideId);
                }
            } catch (error) {
                logger.error(`Error processing fallback queue for ride ${rideId}:`, error);
            }
        }
    }

    async handleFailedUpdate(rideId, location) {
        await this.addToFallbackQueue(rideId, location);
    }
}

// Create singleton instance
const locationFallbackService = new LocationFallbackService();
locationFallbackService.start();

module.exports = locationFallbackService; 