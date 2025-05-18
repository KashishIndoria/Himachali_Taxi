const mongoose = require('mongoose');

const videoCallSchema = new mongoose.Schema({
    initiator: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    recipient: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    ride: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Ride',
        required: true
    },
    status: {
        type: String,
        enum: ['initiated', 'connected', 'ended', 'missed'],
        default: 'initiated'
    },
    startTime: {
        type: Date,
        default: Date.now
    },
    endTime: {
        type: Date
    },
    duration: {
        type: Number,
        get: function() {
            if (this.endTime) {
                return (this.endTime - this.startTime) / 1000; // Duration in seconds
            }
            return 0;
        }
    }
}, {
    timestamps: true,
    toJSON: { getters: true }
});

module.exports = mongoose.model('VideoCall', videoCallSchema); 