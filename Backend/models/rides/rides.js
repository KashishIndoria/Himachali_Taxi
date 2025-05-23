const mongoose = require('mongoose');

const Schema = mongoose.Schema; // Use Schema alias for consistency

// Define GeoJSON Point schema
const pointSchema = new Schema({
    type: {
        type: String,
        enum: ['Point'],
        required: true,
        default: 'Point'
    },
    coordinates: {
        type: [Number], // [longitude, latitude] order
        required: true
    },
    address: { // Optional: Store reverse-geocoded address
        type: String
    }
}, { _id: false });

const locationSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
    },
    coordinates: {
        type: [Number],
        required: true
    },
    address: {
        type: String,
        required: true
    }
});

const RideSchema = new Schema({ // Use Schema alias
    user: { // Renamed from userId
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'User ID is required']
    },
    captain: { // Renamed from captainId
        type: Schema.Types.ObjectId,
        ref: 'Captain',
        default: null
    },
    pickupLocation: { // Use pointSchema
        type: pointSchema,
        required: true
    },
    dropoffLocation: { // Renamed from dropLocation and use pointSchema
        type: pointSchema,
        required: true
    },
    status: { // Expanded enum and default changed
        type: String,
        enum: [
            'Pending',
            'Accepted',
            'Arrived',
            'Started',
            'Completed',
            'CancelledByUser',
            'CancelledByDriver'
        ],
        default: 'Pending',
        required: true,
        index: true // Index status for faster querying
    },
    fare: {
        base: { type: Number, required: true },
        distance: { type: Number, required: true },
        time: { type: Number, required: true },
        total: { type: Number, required: true }
    },
    distance: {
        type: Number,
        required: true
    },
    estimatedTime: {
        type: Number,
        required: true
    },
    actualStartTime: Date,
    actualEndTime: Date,
    paymentMethod: {
        type: String,
        enum: ['cash', 'card', 'wallet'],
        default: 'cash'
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'completed', 'failed'],
        default: 'pending'
    },
    cancellationReason: {
        type: String
    },
    cancelledBy: {
        type: String,
        enum: ['user', 'captain']
    },
    rating: {
        user: {
            rating: { type: Number, min: 1, max: 5 },
            review: String,
            createdAt: Date
        },
        captain: {
            rating: { type: Number, min: 1, max: 5 },
            review: String,
            createdAt: Date
        }
    },
    rideRoute: {
        type: {
            type: String,
            enum: ['LineString'],
            default: 'LineString'
        },
        coordinates: {
            type: [[Number]],
            default: []
        }
    },
    currentLocation: {
        type: locationSchema
    },
    rideMetrics: {
        actualDistance: { type: Number, default: 0 },
        actualDuration: { type: Number, default: 0 },
        waitingTime: { type: Number, default: 0 }
    },
    requestedAt: {
        type: Date,
        default: Date.now // Set when ride is created
    },
    acceptedAt: { type: Date },
    arrivedAt: { type: Date },
    startedAt: { type: Date },
    completedAt: { type: Date },
    cancelledAt: { type: Date },
    estimatedFare: { type: Number },
    finalFare: { type: Number },
    duration: { type: Number }, // in seconds or minutes
    routePolyline: { type: String }, // Encoded polyline for map display
}, {
    timestamps: true // Automatically adds createdAt and updatedAt
});

// Update geospatial index to use the correct field path
RideSchema.index({ pickupLocation: '2dsphere' });

// Add other recommended indices
RideSchema.index({ captain: 1, status: 1 });
RideSchema.index({ user: 1, status: 1 });

// Indexes for geospatial queries
RideSchema.index({ 'pickupLocation.coordinates': '2dsphere' });
RideSchema.index({ 'dropoffLocation.coordinates': '2dsphere' });
RideSchema.index({ 'currentLocation.coordinates': '2dsphere' });

// Method to calculate fare
RideSchema.methods.calculateFare = async function() {
    const BASE_FARE = 50; // Base fare in rupees
    const PER_KM_RATE = 12; // Rate per kilometer
    const PER_MINUTE_RATE = 2; // Rate per minute
    
    this.fare = {
        base: BASE_FARE,
        distance: this.distance * PER_KM_RATE,
        time: this.estimatedTime * PER_MINUTE_RATE,
        total: BASE_FARE + (this.distance * PER_KM_RATE) + (this.estimatedTime * PER_MINUTE_RATE)
    };
    
    return this.fare;
};

// Method to update ride status
RideSchema.methods.updateStatus = async function(newStatus, location = null) {
    this.status = newStatus;
    
    if (location) {
        this.currentLocation = location;
    }
    
    if (newStatus === 'started') {
        this.actualStartTime = new Date();
    } else if (newStatus === 'completed') {
        this.actualEndTime = new Date();
        // Calculate actual metrics
        this.rideMetrics.actualDuration = 
            (this.actualEndTime - this.actualStartTime) / 1000 / 60; // in minutes
    }
    
    await this.save();
    return this;
};

// Check if the model already exists before compiling it
module.exports = mongoose.models.Ride || mongoose.model('Ride', RideSchema);