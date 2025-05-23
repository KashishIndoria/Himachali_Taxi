const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const pointSchema = new Schema({
    type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
    },
    coordinates: {
        type: [Number],
        required: true
    }
});

const userSchema = new Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    password: {
        type: String,
        required: true
    },
    phone: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['PASSENGER', 'CAPTAIN', 'ADMIN'],
        default: 'PASSENGER'
    },
    status: {
        type: String,
        enum: ['AVAILABLE', 'BUSY', 'OFFLINE'],
        default: 'OFFLINE'
    },
    currentLocation: {
        type: pointSchema
    },
    vehicle: {
        type: {
            type: String,
            enum: ['CAR', 'BIKE', 'AUTO']
        },
        model: String,
        number: String,
        capacity: Number
    },
    rating: {
        average: {
            type: Number,
            default: 0
        },
        count: {
            type: Number,
            default: 0
        }
    },
    documents: [{
        type: {
            type: String,
            enum: ['LICENSE', 'REGISTRATION', 'INSURANCE', 'PERMIT']
        },
        number: String,
        expiryDate: Date,
        verified: {
            type: Boolean,
            default: false
        },
        url: String
    }]
}, {
    timestamps: true
});

// Create geospatial index for captain location
userSchema.index({ 'currentLocation': '2dsphere' });

// Method to update rating
userSchema.methods.updateRating = function(newRating) {
    const oldTotal = this.rating.average * this.rating.count;
    this.rating.count += 1;
    this.rating.average = (oldTotal + newRating) / this.rating.count;
};

// Check if the model already exists before compiling it
module.exports = mongoose.models.User || mongoose.model('User', userSchema);