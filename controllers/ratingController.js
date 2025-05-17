const Rating = require('../models/captain/rating'); 
const Ride = require('../models/rides/rides');
const Captain = require('../models/captain/captain');
const mongoose = require('mongoose');

// Submit a rating for a completed ride
exports.submitRating = async (req, res) => {
    const { rideId, rating, comment } = req.body;
    const userId = req.user?.id;

    if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    if (!mongoose.Types.ObjectId.isValid(rideId)) {
        return res.status(400).json({ message: 'Invalid Ride ID format' });
    }

    const numericRating = Number(rating);
    if (isNaN(numericRating) || numericRating < 1 || numericRating > 5) {
        return res.status(400).json({ message: 'Rating must be a number between 1 and 5' });
    }

    try {
        // 1. Find the ride
        const ride = await Ride.findById(rideId);
        if (!ride) {
            return res.status(404).json({ message: 'Ride not found' });
        }

        // 2. Check if the user requesting was part of this ride
        if (ride.user?.toString() !== userId) {
            return res.status(403).json({ message: 'You can only rate rides you took' });
        }
        if (ride.status !== 'Completed') {
             return res.status(400).json({ message: 'You can only rate completed rides' });
        }

        // 4. Check if the user already rated this ride
        const existingRating = await Rating.findOne({ ride: rideId, user: userId });
        if (existingRating) {
            return res.status(400).json({ message: 'You have already rated this ride' });
        }

        // 5. Ensure the ride has a captain assigned
        if (!ride.captain) {
             return res.status(400).json({ message: 'Cannot rate a ride with no assigned driver/captain.' });
        }


        // 6. Create and save the rating
        const newRating = new Rating({
            ride: rideId,
            user: userId,
            driver: ride.captain, // Use the captain ID stored in the ride document
            rating: numericRating,
            comment: comment // Optional comment
        });

        await newRating.save();

        // 7. (Optional but recommended) Update the driver's average rating in the Captain model
        // This often involves fetching all ratings for the driver and recalculating.
        // Consider doing this asynchronously or via a database trigger for performance.
        // Example (simplified, potentially slow for many ratings):
        const stats = await Rating.aggregate([
            { $match: { driver: ride.captain } },
            { $group: { _id: "$driver", avgRating: { $avg: "$rating" }, ratingCount: { $sum: 1 } } }
        ]);

        if (stats.length > 0) {
            await Captain.findByIdAndUpdate(ride.captain, {
                averageRating: stats[0].avgRating.toFixed(2),
                totalRatings: stats[0].ratingCount
                // Add fields like averageRating and totalRatings to your Captain model
            });
        }


        res.status(201).json({ message: 'Rating submitted successfully', rating: newRating });

    } catch (error) {
        console.error('Error submitting rating:', error);
        // Provide more specific error messages if possible
        if (error.name === 'ValidationError') {
             res.status(400).json({ message: 'Validation Error', errors: error.errors });
        } else {
             res.status(500).json({ message: 'Server error while submitting rating' });
        }
    }
};

// Get all ratings for a specific driver
exports.getDriverRatings = async (req, res) => {
    const { driverId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(driverId)) {
        return res.status(400).json({ message: 'Invalid Driver ID format' });
    }

    try {
        const ratings = await Rating.find({ driver: driverId })
            .populate('user', 'name profilePicture') // Populate user details you want to show
            .sort({ timestamp: -1 }); // Show newest first

        // Fetch the captain's calculated average rating (if stored)
        const captain = await Captain.findById(driverId).select('averageRating totalRatings');

        res.status(200).json({
             ratings,
             averageRating: captain?.averageRating || 0,
             totalRatings: captain?.totalRatings || 0
        });

    } catch (error) {
        console.error('Error fetching driver ratings:', error);
        res.status(500).json({ message: 'Server error while fetching ratings' });
    }
};

// Get all ratings submitted by the currently logged-in user
exports.getMyRatings = async (req, res) => {
    const userId = req.user?.id;

     if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    try {
        const ratings = await Rating.find({ user: userId })
            .populate('driver', 'name profilePicture averageRating') // Populate driver details
            .populate('ride', 'pickupLocation.address dropoffLocation.address rideEndTime') // Populate relevant ride details
            .sort({ timestamp: -1 });

        res.status(200).json(ratings);
    } catch (error) {
        console.error('Error fetching user ratings:', error);
        res.status(500).json({ message: 'Server error while fetching your ratings' });
    }
};