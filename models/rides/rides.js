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

// Remove the old locationSchema if it exists
// const locationSchema = new mongoose.Schema({ ... }); // Remove this

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
    // Remove old fare field, use optional fields below if needed
    // fare: { type: Number, required: true },

    // Add specific timestamps
    requestedAt: {
        type: Date,
        default: Date.now // Set when ride is created
    },
    acceptedAt: { type: Date },
    arrivedAt: { type: Date },
    startedAt: { type: Date },
    completedAt: { type: Date },
    cancelledAt: { type: Date },

    // Optional fields (can be added/used later)
    estimatedFare: { type: Number },
    finalFare: { type: Number },
    distance: { type: Number }, // in meters or km
    duration: { type: Number }, // in seconds or minutes
    routePolyline: { type: String }, // Encoded polyline for map display
    paymentMethod: { type: String },
    paymentStatus: { type: String, enum: ['Pending', 'Paid', 'Failed'], default: 'Pending' }


}, {
    timestamps: true // Automatically adds createdAt and updatedAt
});

// Update geospatial index to use the correct field path
RideSchema.index({ pickupLocation: '2dsphere' });

// Add other recommended indices
RideSchema.index({ captain: 1, status: 1 });
RideSchema.index({ user: 1, status: 1 });


module.exports = mongoose.model('Ride', RideSchema);


// Add geospatial index for pickupLocation
RideSchema.index({ "pickupLocation.coordinates": '2dsphere' });

module.exports = mongoose.model('Ride', RideSchema);