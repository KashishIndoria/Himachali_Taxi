const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ratingSchema = new Schema({
    ride: {
        type: Schema.Types.ObjectId,
        ref: 'Ride', 
        required: true,
        index: true
    },
    user: { 
        type: Schema.Types.ObjectId,
        ref: 'User', 
        required: true
    },
    driver: { 
        type: Schema.Types.ObjectId,
        ref: 'Captain', 
        required: true,
        index: true
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        trim: true,
        default: null // Optional comment
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

// Ensure a user can only rate a specific ride once
ratingSchema.index({ ride: 1, user: 1 }, { unique: true });


ratingSchema.index({ driver: 1, timestamp: -1 });

const Rating = mongoose.model('Rating', ratingSchema);

module.exports = Rating;