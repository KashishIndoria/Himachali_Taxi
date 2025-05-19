const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const captainSchema = new mongoose.Schema({
    firstName: {
        type: String,
        required: [true, 'First name is required'],
        trim: true,
        minlength: [2, 'First name must be at least 2 characters long'],
        maxlength: [50, 'First name cannot exceed 50 characters']
    },
    lastName: {
        type: String,
        required: [true, 'Last name is required'],
        trim: true,
        minlength: [2, 'Last name must be at least 2 characters long'],
        maxlength: [50, 'Last name cannot exceed 50 characters']
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        trim: true,
        lowercase: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
    },
    phone: {
        type: String,
        required: [true, 'Phone number is required'],
        unique: true,
        trim: true,
        match: [/^\+?[1-9]\d{9,14}$/, 'Please enter a valid phone number']
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters long'],
        select: false
    },
    profileImage: {
        type: String,
        validate: {
            validator: function(v) {
                return !v || /^https?:\/\/.+\.(jpg|jpeg|png|gif)$/i.test(v);
            },
            message: 'Profile image must be a valid image URL'
        }
    },
    vehicleDetails: {
        model: {
            type: String,
            required: [true, 'Vehicle model is required'],
            trim: true
        },
        plateNumber: {
            type: String,
            required: [true, 'Plate number is required'],
            trim: true,
            uppercase: true
        },
        color: {
            type: String,
            required: [true, 'Vehicle color is required'],
            trim: true
        },
        year: {
            type: Number,
            required: [true, 'Vehicle year is required'],
            min: [1900, 'Invalid vehicle year'],
            max: [new Date().getFullYear() + 1, 'Invalid vehicle year']
        }
    },
    drivingLicense: {
        number: {
            type: String,
            required: [true, 'License number is required'],
            trim: true,
            uppercase: true
        },
        expiryDate: {
            type: Date,
            required: [true, 'License expiry date is required'],
            validate: {
                validator: function(v) {
                    return v > new Date();
                },
                message: 'License must not be expired'
            }
        },
        issuingAuthority: {
            type: String,
            required: [true, 'Issuing authority is required'],
            required: [true, 'License state is required'],
            trim: true
        },
        verified: {
            type: Boolean,
            default: false
        }
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number],
            default: [0, 0],
            validate: {
                validator: function(v) {
                    return v.length === 2 && 
                           v[0] >= -180 && v[0] <= 180 && // longitude
                           v[1] >= -90 && v[1] <= 90;     // latitude
                },
                message: 'Invalid coordinates'
            }
        },
        heading: {
            type: Number,
            default: 0,
            min: 0,
            max: 360
        },
        speed: {
            type: Number,
            default: 0,
            min: 0,
            max: 200
        },
        lastUpdated: {
            type: Date,
            default: Date.now
        }
    },
    isOnline: {
        type: Boolean,
        default: false,
        index: true
    },
    isAvailable: {
        type: Boolean,
        default: false,
        index: true
    },
    isVerified: {
        type: Boolean,
        default: false,
        index: true
    },
    averageRating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
        get: v => Math.round(v * 10) / 10 // Round to 1 decimal place
    },
    totalRatings: {
        type: Number,
        default: 0,
        min: 0
    },
    totalRides: {
        type: Number,
        default: 0,
        min: 0
    },
    totalEarnings: {
        type: Number,
        default: 0,
        min: 0,
        get: v => Math.round(v * 100) / 100 // Round to 2 decimal places
    },
    socketId: {
        type: String,
        default: null,
        index: true
    },
    deviceToken: {
        type: String,
        trim: true
    },
    lastSeen: {
        type: Date,
        default: Date.now
    },
    accountStatus: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'suspended', 'inactive'],
        default: 'pending',
        index: true
    },
    otp: {
        code: String,
        expiresAt: Date
    },
    createdAt: {
        type: Date,
        default: Date.now,
        immutable: true
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' },
    toJSON: { getters: true }, // Enable getters when converting to JSON
    toObject: { getters: true } // Enable getters when converting to Object
});

// Create indexes
captainSchema.index({ location: '2dsphere' });
captainSchema.index({ 'vehicleDetails.licensePlate': 1 });
captainSchema.index({ 'drivingLicense.number': 1 });
captainSchema.index({ createdAt: -1 });
captainSchema.index({ updatedAt: -1 });

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

// Method to check if captain is active
captainSchema.methods.isActive = function() {
    return this.accountStatus === 'approved' && !this.isSuspended;
};

// Method to check if captain can accept rides
captainSchema.methods.canAcceptRides = function() {
    return this.isActive() && this.isOnline && this.isAvailable && this.isVerified;
};

module.exports = mongoose.model('Captain', captainSchema);