const mongoose = require('mongoose');

const safetyVideoSchema = new mongoose.Schema({
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
    videoUrl: {
        type: String,
        required: [true, 'Please add a video URL']
    },
    uploadedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    views: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    },
    category: {
        type: String,
        enum: ['road-safety', 'passenger-safety', 'emergency-response', 'general-safety'],
        required: true
    }
}, {
    timestamps: true
});

// Increment views
safetyVideoSchema.methods.incrementViews = async function() {
    this.views += 1;
    await this.save();
};

module.exports = mongoose.model('SafetyVideo', safetyVideoSchema); 