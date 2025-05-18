const mongoose = require('mongoose');

const trainingVideoSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Please add a title'],
        trim: true,
        maxlength: [100, 'Title cannot be more than 100 characters']
    },
    description: {
        type: String,
        required: [true, 'Please add a description'],
        maxlength: [500, 'Description cannot be more than 500 characters']
    },
    category: {
        type: String,
        required: [true, 'Please specify a category'],
        enum: [
            'safety',
            'customer-service',
            'navigation',
            'vehicle-maintenance',
            'local-regulations',
            'emergency-procedures'
        ]
    },
    videoUrl: {
        type: String,
        required: [true, 'Please add a video URL']
    },
    uploadedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    requiredFor: [{
        type: String,
        enum: ['new-drivers', 'all-drivers', 'premium-drivers']
    }],
    duration: {
        type: Number, // Duration in seconds
        required: [true, 'Please specify video duration']
    },
    views: {
        type: Number,
        default: 0
    },
    completions: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        completedAt: {
            type: Date,
            default: Date.now
        },
        score: {
            type: Number
        }
    }],
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Increment views
trainingVideoSchema.methods.incrementViews = async function() {
    this.views += 1;
    await this.save();
};

// Mark video as completed for a user
trainingVideoSchema.methods.markCompleted = async function(userId, score = null) {
    this.completions.push({
        user: userId,
        score: score
    });
    await this.save();
};

module.exports = mongoose.model('TrainingVideo', trainingVideoSchema); 