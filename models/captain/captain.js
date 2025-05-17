const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const captainSchema = new mongoose.Schema({
    firstName: {
        type: String,
        required: [true, 'First name is required'],
        trim: true,
    },
    lastName: {
        type: String,
        required: [true, 'Last name is required'],
        trim: true,
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
    },
    phone: {
        type: String,
        required: [true, 'Phone number is required'],
        unique: true,
        trim: true,
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters'],
        select: false // Password won't be returned by default in queries
    },
    profileImage: {
        type: String,
        default: '',
    },
    vehicleDetails: {
        make: String,
        model: String,
        year: Number,
        licensePlate: {
            type: String,
            unique: true,
            sparse: true // Allows null values but enforces uniqueness for non-null values
        },
        color: String
    },
    drivingLicense: {
        number: String,
        expiry: Date,
        state: String,
        verified: {
            type: Boolean,
            default: false,
        },
    },
    location: { // GeoJSON Point
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point',
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            default: [0, 0],
        },
        heading: { // Optional: Direction the captain is facing
            type: Number,
            default: 0,
        },
        speed: { // Optional: Current speed
            type: Number,
            default: 0,
        },
        lastUpdated: { // Timestamp of the last location update
            type: Date,
            default: Date.now,
        },
    },
    isOnline: { // General connection status (e.g., connected to WebSocket)
        type: Boolean,
        default: false,
        index: true // Index for faster querying of online captains
    },
    isAvailable: { // Availability status for accepting ride requests
        type: Boolean,
        default: false
    },
    isVerified: { // Account verification status (e.g., documents checked)
        type: Boolean,
        default: false
    },
    averageRating: { // Changed from 'rating' to 'averageRating' for clarity
        type: Number,
        default: 0,
        min: 0,
        max: 5,
    },
    totalRatings: { // Number of ratings received
        type: Number,
        default: 0
    },
    totalRides: { // Total completed rides
        type: Number,
        default: 0,
    },
    totalEarnings: { // Total earnings
        type: Number,
        default: 0,
    },
    socketId: { // Current WebSocket connection ID
        type: String,
        default: null, // Use null instead of empty string for clarity
        index: true // Index for potentially faster lookups by socket ID
    },
    deviceToken: String, // For push notifications
    lastSeen: { // Timestamp of the last activity or connection
        type: Date,
        default: Date.now
    },
    accountStatus: { // Overall account status
        type: String,
        enum: ['pending', 'approved', 'rejected', 'suspended', 'inactive'], // Added 'inactive'
        default: 'pending'
    },
    otp: { // For phone verification or password reset
        code: String,
        expiresAt: Date
    },
    createdAt: {
        type: Date,
        default: Date.now,
        immutable: true // Cannot be changed after creation
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    }
}, {
    timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' } // Use Mongoose built-in timestamps
});

// Create index for geo queries
captainSchema.index({ location: '2dsphere' });

// Hash password before saving
captainSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Update the updatedAt field
captainSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Method to check password
captainSchema.methods.comparePassword = async function(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Captain', captainSchema);