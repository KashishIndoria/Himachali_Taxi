const User = require('../models/user/User');
const Ride = require('../models/rides/rides');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Request a new ride
exports.requestRide = async (req, res) => {
    try {
        const { pickupLocation, dropoffLocation, fare } = req.body;
        const userId = req.user.id; // Get from JWT token

        const ride = new Ride({
            userId,
            pickupLocation,
            dropoffLocation,
            fare,
            status: 'requested'
        });

        await ride.save();

        res.status(201).json({
            status: 'success',
            message: 'Ride requested successfully',
            data: {
                rideId: ride._id,
                status: ride.status
            }
        });
    } catch (error) {
        console.error('Ride request error:', error);
        res.status(500).json({
            status: 'error',
            message: 'Failed to request ride'
        });
    }
};

// Get user's ride history
exports.getRideHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const rides = await Ride.find({ userId })
            .sort({ createdAt: -1 })
            .populate('captainId', 'name');

        res.status(200).json({
            status: 'success',
            data: rides
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: 'Failed to fetch ride history'
        });
    }
};

// Cancel a ride
exports.cancelRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const userId = req.user.id;

        const ride = await Ride.findOne({ _id: rideId, userId });

        if (!ride) {
            return res.status(404).json({
                status: 'error',
                message: 'Ride not found'
            });
        }

        if (ride.status !== 'requested') {
            return res.status(400).json({
                status: 'error',
                message: 'Cannot cancel ride in current status'
            });
        }

        ride.status = 'cancelled';
        await ride.save();

        res.status(200).json({
            status: 'success',
            message: 'Ride cancelled successfully'
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: 'Failed to cancel ride'
        });
    }
};