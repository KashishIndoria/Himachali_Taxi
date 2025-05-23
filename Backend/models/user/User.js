const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    firstName: {
        type: String,
        required: [true, 'First name is required'],
        trim: true
    },
    lastName: {
        type: String,
        trim: true
    },
    phone:{
        type: String,
        // required: [true, 'Phone number is required'],
        trim: true,
        unique: true,
        match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters'],
        select: false
    },
    role: {
        type: String,
        enum: ['user', 'driver', 'admin'],
        default: 'user'
    },
    gender: {
        type: String,
        enum:['Male','Female','Other'],
        default: 'Male'
    },
    dateOfBirth: {
        type: Date
    },
    address: {
        type: String,
        trim: true
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    otp :{
        code : String,
        expiresAt : Date,
    },
    profileImage:{
        type: String,
        default: '',
    },
    rating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
    },
    totalRides: {
        type: Number,
        default: 0,
    },
    socketId: {
        type: String,
        default: null,
        index: true // Index for faster lookup if needed
    },
    favorites: [
        {
            name: String,
            address: String,
            latitude: Number,
            longitude: Number,
            type: {
                type: String,
                enum: ['home', 'work', 'other'],
                default: 'other',
            },
        },
    ],
    paymentMethods: [
        {
            type: {
                type: String,
                enum: ['card', 'upi', 'cash'],
                default: 'cash',
            },
            default: {
                type: Boolean,
                default: false,
            },
            details: {
                type: mongoose.Schema.Types.Mixed,
            },
        },
    ],
    deviceToken: String,
    lastActive: {
        type: Date,
        default: Date.now,
    },
    accountStatus: {
        type: String,
        enum: ['active', 'suspended', 'inactive'],
        default: 'active',
    }
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Update the updatedAt field (already handled by timestamps but added for completeness)
userSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

// Check if the model already exists before compiling it
module.exports = mongoose.models.User || mongoose.model('User', userSchema);