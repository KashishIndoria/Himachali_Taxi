const User = require('../models/user/User');
const Captain = require('../models/captain/captain');
const jwt = require('jsonwebtoken');
const generateOTP = require('../utils/generaterandomotp');
const { otpEmailTemplate, successEmailTemplate } = require('../utils/emailTemplate');
const { sendEmail } = require('../services/emailService');

exports.userSignup = async (req, res) => {
    try {
        const { firstName, email, password } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                status: 'error',
                message: 'Email already registered'
            });
        }

        // Generate OTP
        const otp = generateOTP();
        const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        // Create new user
        const user = await User.create({
            firstName,
            email,
            password,
            isVerified: false,
            otp: { code: otp, expiresAt: otpExpiresAt },
        });

        // Generate JWT token
        const token = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );


        // Send verification email
        await user.save();

        // Send verification email
        const emailSent = await sendEmail(
            email,
            'Email Verification',
            otpEmailTemplate(otp)
        );

        if (!emailSent) {
            return res.status(500).json({ message: 'Failed to send verification email' });
        }

        res.status(201).json({
            message: 'Registration successful. Please check your email for OTP verification.',
            userId: user._id
        });

    } catch (error) {
        res.status(500).json({ message: 'Error during registration', error: error.message });
    }
};

exports.captainSignup = async (req, res) => {
    try {
        const {
            firstName,
            lastName,
            email,
            password,
            phone,
            vehicleDetails,
            isAvailable
        } = req.body;

        // Check if captain exists
        const existingCaptain = await Captain.findOne({
            $or: [{ email }, { phone }]
        });

        if (existingCaptain) {
            return res.status(400).json({
                status: 'error',
                message: existingCaptain.email === email
                    ? 'Email already registered'
                    : 'Phone number already registered'
            });
        }

        // Generate OTP
        const otp = generateOTP();
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        // Create new captain
        const captain = await Captain.create({
            firstName,
            lastName,
            email,
            password,
            vehicleDetails : vehicleDetails || {},
            isAvailable: isAvailable || false,
            isVerified: false,
            otp: { code: otp, expiresAt: otpExpiresAt }
        });

        // Send verification email
        const emailSent = await sendEmail(
            email,
            'Captain Verification - Himachali Taxi',
            otpEmailTemplate(otp)
        );

        if (!emailSent) {
            return res.status(500).json({
                status: 'error',
                message: 'Failed to send verification email'
            });
        }

        res.status(201).json({
            status: 'success',
            message: 'Registration successful. Please check your email for OTP verification.',
            captainId: captain._id
        });

    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: 'Error during registration',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

exports.verifyOTP = async (req, res) => {
    try {
        const { email, otp, role } = req.body;
        console.log('Verification attempt:', { email, otp, role });

        const Model = role === 'captain' ? Captain : User;
        const user = await Model.findOne({ email }).select('+otp');

        if (!user) {
            return res.status(404).json({
                status: 'error',
                message: `${role === 'captain' ? 'Captain' : 'User'} not found`
            });
        }

        // Verify OTP
        if (!user.otp || user.otp.code !== otp) {
            return res.status(400).json({
                status: 'error',
                message: 'Invalid OTP'
            });
        }

        // Update verification status
        user.isVerified = true;
        user.otp = undefined;
        await user.save();

        // Send welcome email
        try {
            const name = role === 'captain' ? user.name : user.firstName;
            const emailSent = await sendEmail(
                user.email,
                'Welcome to Himachali Taxi - Account Created Successfully',
                successEmailTemplate(name, role)
            );

            if (!emailSent) {
                console.log('Welcome email failed to send');
            } else {
                console.log('Welcome email sent successfully to:', email);
            }
        } catch (emailError) {
            console.error('Welcome email sending failed:', emailError);
        }

        return res.status(200).json({
            status: 'success',
            message: 'Account verified successfully'
        });

    } catch (error) {
        console.error('Verification error:', error);
        return res.status(500).json({
            status: 'error',
            message: 'Error during verification'
        });
    }
};
exports.resendOTP = async (req, res) => {
    try {
        const { email, role } = req.body;

        // Select the appropriate model based on role
        const Model = role === 'captain' ? Captain : User;
        const user = await Model.findOne({ email });

        if (!user) {
            return res.status(404).json({
                status: 'error',
                message: `${role === 'captain' ? 'Captain' : 'User'} not found`
            });
        }

        if (user.isVerified) {
            return res.status(400).json({
                status: 'error',
                message: 'Email is already verified'
            });
        }

        // Generate new OTP
        const otp = generateOTP();
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        // Update user with new OTP
        user.otp = { code: otp, expiresAt: otpExpiresAt };
        await user.save();

        // Send new verification email
        const emailSent = await sendEmail(
            email,
            `${role === 'captain' ? 'Captain' : 'User'} Verification - Himachali Taxi`,
            otpEmailTemplate(otp)
        );

        if (!emailSent) {
            return res.status(500).json({
                status: 'error',
                message: 'Failed to send verification email'
            });
        }

        res.status(200).json({
            status: 'success',
            message: 'New OTP has been sent to your email'
        });

    } catch (error) {
        console.error('Resend OTP error:', error);
        res.status(500).json({
            status: 'error',
            message: 'Error resending OTP',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

const handleLogin = async (Model, email, password, role) => {
    const user = await Model.findOne({ email }).select('+password');

    if (!user || !(await user.comparePassword(password))) {
        return {
            status: 401,
            data: {
                status: 'error',
                message: 'Invalid email or password'
            }
        };
    }

    if (!user.isVerified) {
        return {
            status: 401,
            data: {
                status: 'error',
                message: 'Please verify your email first'
            }
        };
    }

    const token = jwt.sign(
        {
            id: user._id,
            email: user.email,
            role,
            firstName :user.firstName,
            lastName : user.lastName || '',
            isCaptain : role === 'captain',
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' } // Changed from 1h to 24h
    );

    // Updated response format
    if (role === 'user') {
        return {
            status: 200,
            data: {
                status: 'success',
                message: 'Login successful',
                token,
                user: {
                    _id: user._id.toString(),
                    email: user.email,
                    firstName: role === 'user' ? user.firstName : user.name,
                    isVerified: user.isVerified,
                    profileImage: user.profileImage || null,
                }
            }
        };
    } else if (role === 'captain') {
        return {
            status: 200,
            data: {
                status: 'success',
                message: 'Login successful',
                token,
                captain: {
                    _id: user._id.toString(),
                    email: user.email,
                    firstName: user.firstName,
                    lastName: user.lastName || '',
                    phone: user.phone,
                    profileImage: user.profileImage || null,
                    vehicleDetails: user.vehicleDetails,
                    isAvailable: user.isAvailable,
                    rating: user.rating || 0,
                    accountStatus: user.accountStatus,
                    isVerified: user.isVerified
                }
            }
        };
    } else {
        return {
            status: 400,
            data: {
                status: 'error',
                message: 'Invalid role'
            }
        };
    }
};


exports.userLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                status: 'error',
                message: 'Please provide email and password'
            });
        }

        const result = await handleLogin(User, email, password, 'user');
        return res.status(result.status).json(result.data);

    } catch (error) {
        console.error('Login error:', error);
        return res.status(500).json({
            status: 'error',
            message: 'An error occurred during login'
        });
    }
};

exports.captainLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                status: 'error',
                message: 'Please provide email and password'
            });
        }

        const result = await handleLogin(Captain, email, password, 'captain');
        return res.status(result.status).json(result.data);

    } catch (error) {
        console.error('Login error:', error);
        return res.status(500).json({
            status: 'error',
            message: 'An error occurred during login'
        });
    }
};
