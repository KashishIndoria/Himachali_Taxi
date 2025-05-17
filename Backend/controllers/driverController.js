const Captain = require('../models/captain/captain');
const Ride = require('../models/rides/rides');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Accept a ride request
exports.acceptRide = async (req, res) => {
    try {
        const { rideId } = req.body;
        const captainId = req.user.id;

        const ride = await Ride.findById(rideId);
        if (!ride) {
            return res.status(404).json({
                status: 'error',
                message: 'Ride not found'
            });
        }

        if (ride.status !== 'requested') {
            return res.status(400).json({
                status: 'error',
                message: 'Ride is no longer available'
            });
        }

        ride.captainId = captainId;
        ride.status = 'accepted';
        await ride.save();

        res.status(200).json({
            status: 'success',
            message: 'Ride accepted successfully',
            data: {
                rideId: ride._id,
                status: ride.status
            }
        });
    } catch (error) {
        console.error('Accept ride error:', error);
        res.status(500).json({
            status: 'error',
            message: 'Failed to accept ride'
        });
    }
};

// Complete a ride
exports.completeRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const captainId = req.user.id;

        const ride = await Ride.findOne({ _id: rideId, captainId });
        if (!ride) {
            return res.status(404).json({
                status: 'error',
                message: 'Ride not found'
            });
        }

        if (ride.status !== 'accepted') {
            return res.status(400).json({
                status: 'error',
                message: 'Cannot complete ride in current status'
            });
        }

        ride.status = 'completed';
        ride.updatedAt = new Date();
        await ride.save();

        res.status(200).json({
            status: 'success',
            message: 'Ride completed successfully'
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: 'Failed to complete ride'
        });
    }
};

// Get captain's ride history
exports.getRideHistory = async (req, res) => {
    try {
        const captainId = req.user.id;
        const rides = await Ride.find({ captainId })
            .sort({ createdAt: -1 })
            .populate('userId', 'firstName');

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