const Ride = require('../models/ride.model');
const RideMatchingService = require('../services/ride-matching.service');
const mongoose = require('mongoose');

class RideController {
    // Book a new ride
    async bookRide(req, res) {
        try {
            const { pickup, dropoff } = req.body;
            
            const ride = new Ride({
                passenger: req.user._id,
                pickup: {
                    location: pickup.location,
                    address: pickup.address
                },
                dropoff: {
                    location: dropoff.location,
                    address: dropoff.address
                },
                status: 'REQUESTED'
            });

            await ride.save();

            // Find nearby captains
            const captains = await RideMatchingService.findCaptainWithDynamicRadius(pickup);
            if (captains.length === 0) {
                return res.status(404).json({ message: 'No captains available nearby' });
            }

            // Notify captains sequentially
            const assignedCaptain = await RideMatchingService.notifyCaptainsSequentially(ride, captains);
            
            return res.status(201).json({
                message: 'Ride request created successfully',
                ride: ride,
                captainFound: !!assignedCaptain
            });
        } catch (error) {
            console.error('Error booking ride:', error);
            return res.status(500).json({ message: 'Error booking ride' });
        }
    }

    // Update ride status and location
    async updateRideStatus(req, res) {
        try {
            const { rideId } = req.params;
            const { status, currentLocation } = req.body;

            const ride = await Ride.findById(rideId);
            if (!ride) {
                return res.status(404).json({ message: 'Ride not found' });
            }

            // Verify that the user is authorized to update this ride
            if (ride.captain.toString() !== req.user._id.toString()) {
                return res.status(403).json({ message: 'Unauthorized to update this ride' });
            }

            // Update location if provided
            if (currentLocation) {
                ride.currentLocation = currentLocation;
            }

            // Update status
            await RideMatchingService.updateRideStatus(rideId, status);

            return res.status(200).json({ message: 'Ride updated successfully', ride });
        } catch (error) {
            console.error('Error updating ride:', error);
            return res.status(500).json({ message: 'Error updating ride' });
        }
    }

    // Get ride history for a user
    async getRideHistory(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const userRole = req.user.role;
            const userId = req.user._id;

            let query = {};
            if (userRole === 'PASSENGER') {
                query.passenger = userId;
            } else if (userRole === 'CAPTAIN') {
                query.captain = userId;
            }

            const rides = await Ride.find(query)
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit)
                .populate('passenger', 'name phone')
                .populate('captain', 'name phone vehicle')
                .select('-__v');

            const total = await Ride.countDocuments(query);

            return res.status(200).json({
                rides,
                pagination: {
                    total,
                    page,
                    pages: Math.ceil(total / limit)
                }
            });
        } catch (error) {
            console.error('Error fetching ride history:', error);
            return res.status(500).json({ message: 'Error fetching ride history' });
        }
    }

    // Get current active ride
    async getCurrentRide(req, res) {
        try {
            const userId = req.user._id;
            const userRole = req.user.role;

            let query = {
                status: { $in: ['REQUESTED', 'ACCEPTED', 'ARRIVED', 'STARTED'] }
            };

            if (userRole === 'PASSENGER') {
                query.passenger = userId;
            } else if (userRole === 'CAPTAIN') {
                query.captain = userId;
            }

            const ride = await Ride.findOne(query)
                .populate('passenger', 'name phone')
                .populate('captain', 'name phone vehicle')
                .select('-__v');

            if (!ride) {
                return res.status(404).json({ message: 'No active ride found' });
            }

            return res.status(200).json({ ride });
        } catch (error) {
            console.error('Error fetching current ride:', error);
            return res.status(500).json({ message: 'Error fetching current ride' });
        }
    }
}

module.exports = new RideController(); 