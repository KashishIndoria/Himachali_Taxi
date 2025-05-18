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

const rideSchema = new Schema({
    passenger: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    captain: {
        type: Schema.Types.ObjectId,
        ref: 'User'
    },
    status: {
        type: String,
        enum: ['REQUESTED', 'ACCEPTED', 'ARRIVED', 'STARTED', 'COMPLETED', 'CANCELLED'],
        default: 'REQUESTED'
    },
    pickup: {
        location: {
            type: pointSchema,
            required: true
        },
        address: String
    },
    dropoff: {
        location: {
            type: pointSchema,
            required: true
        },
        address: String
    },
    currentLocation: {
        type: pointSchema
    },
    distance: {
        type: Number,
        default: 0
    },
    duration: {
        type: Number,
        default: 0
    },
    fare: {
        base: Number,
        distance: Number,
        time: Number,
        total: Number
    },
    payment: {
        status: {
            type: String,
            enum: ['PENDING', 'COMPLETED', 'FAILED'],
            default: 'PENDING'
        },
        method: {
            type: String,
            enum: ['CASH', 'CARD', 'WALLET'],
            default: 'CASH'
        },
        transactionId: String
    },
    rating: {
        passenger: {
            rating: { type: Number, min: 1, max: 5 },
            comment: String
        },
        captain: {
            rating: { type: Number, min: 1, max: 5 },
            comment: String
        }
    },
    timestamps: {
        requested: { type: Date, default: Date.now },
        accepted: Date,
        arrived: Date,
        started: Date,
        completed: Date,
        cancelled: Date
    }
}, {
    timestamps: true
});

// Create geospatial indexes
rideSchema.index({ 'pickup.location': '2dsphere' });
rideSchema.index({ 'dropoff.location': '2dsphere' });
rideSchema.index({ 'currentLocation': '2dsphere' });

// Methods
rideSchema.methods.calculateFare = function() {
    const BASE_FARE = 50; // Base fare in rupees
    const PER_KM_RATE = 12; // Rate per kilometer
    const PER_MINUTE_RATE = 2; // Rate per minute

    this.fare = {
        base: BASE_FARE,
        distance: this.distance * PER_KM_RATE,
        time: this.duration * PER_MINUTE_RATE,
        total: BASE_FARE + (this.distance * PER_KM_RATE) + (this.duration * PER_MINUTE_RATE)
    };
    return this.fare;
};

rideSchema.methods.updateStatus = async function(newStatus) {
    const validTransitions = {
        'REQUESTED': ['ACCEPTED', 'CANCELLED'],
        'ACCEPTED': ['ARRIVED', 'CANCELLED'],
        'ARRIVED': ['STARTED', 'CANCELLED'],
        'STARTED': ['COMPLETED', 'CANCELLED'],
        'COMPLETED': [],
        'CANCELLED': []
    };

    if (!validTransitions[this.status].includes(newStatus)) {
        throw new Error(`Invalid status transition from ${this.status} to ${newStatus}`);
    }

    this.status = newStatus;
    this.timestamps[newStatus.toLowerCase()] = new Date();
    await this.save();
    return this;
};

const Ride = mongoose.model('Ride', rideSchema);
module.exports = Ride; 