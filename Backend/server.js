const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const socketIO = require('socket.io');
const http = require('http');
const logger = require('./utils/logger');
const jwt = require('jsonwebtoken');

// Load environment variables
dotenv.config();

// Routes
// const authRoutes = require('./routes/auth.routes'); // Comment out or remove old auth routes
const authApiRoutes = require('./routes/authroutes'); // Use the new auth routes
const rideRoutes = require('./routes/ride.routes');
// const userRoutes = require('./routes/user.routes');
const captainRoutes = require('./routes/captainroutes');
const locationRoutes = require('./routes/locationroutes');
const profileRoutes = require('./routes/profileroutes');
const ratingRoutes = require('./routes/ratingroutes');
const videoCallRoutes = require('./routes/videoCall.routes');
const bookingRoutes = require('./routes/booking.routes.js'); 
const { type } = require('os');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
    cors: {
        origin: process.env.BACKEND_URL || "http://localhost:3000",
        methods: ["GET", "POST"]
    }
});

// Make io available globally
global.io = io;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Database connection with retry mechanism
const connectDB = async (retries = 5) => {
    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/himachali_taxi', {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });
        console.log('Connected to MongoDB');
    } catch (err) {
        console.error('MongoDB connection error:', err);
        if (retries > 0) {
            console.log(`Retrying connection... (${retries} attempts left)`);
            setTimeout(() => connectDB(retries - 1), 5000);
        } else {
            console.error('Failed to connect to MongoDB after multiple attempts');
            process.exit(1);
        }
    }
};

connectDB();

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    socket.on('authenticate', async (token) => {
        try {
            // Verify token and get user
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
            const user = await User.findById(decoded.userId);
            
            if (user) {
                socket.userId = user._id;
                socket.join(user._id.toString());
                socket.emit('authenticated', { userId: user._id });
                
                if (user.role === 'CAPTAIN') {
                    socket.join('captains');
                }
            }
        } catch (error) {
            socket.emit('auth_error', { message: 'Authentication failed' });
        }
    });

    socket.on('location_update', async (data) => {
        if (!socket.userId) return;

        try {
            const user = await User.findById(socket.userId);
            if (user && user.role === 'CAPTAIN') {
                user.currentLocation = {
                    type: 'Point',
                    coordinates: [data.longitude, data.latitude]
                };
                await user.save();

                // If captain is on a ride, notify the passenger
                const activeRide = await Ride.findOne({
                    captain: user._id,
                    status: { $in: ['ACCEPTED', 'ARRIVED', 'STARTED'] }
                });

                if (activeRide) {
                    io.to(activeRide.passenger.toString()).emit('captain_location', {
                        rideId: activeRide._id,
                        location: user.currentLocation
                    });
                }
            }
        } catch (error) {
            console.error('Error updating location:', error);
        }
    });

    socket.on('ride_request', async (data) =>{
        console.log('Ride request received:', data);

        try{
            if(!socket.userId){
                socket.emit('error', { message: 'User not authenticated' });
                return;
            }

        const {
            pickupLocation,
            dropoffLocation,
            estimatedFare,
            paymentMethod,
            status,
        } = data;

        const newBooking = new Booking({
            userId: socket.userId,
            pickupLocation :{
                type: 'Point',
                coordinates: [pickupLocation.longitude, pickupLocation.latitude],
                address: pickupLocation.address
            },
            dropoffLocation: {
                type: 'Point',
                coordinates: [dropoffLocation.longitude, dropoffLocation.latitude],
                address: dropoffLocation.address
            },
            estimatedFare: estimatedFare,
            paymentMethod: paymentMethod || 'CASH',
            status: status || 'PENDING',
        });

        await newBooking.save();
        console.log('Booking created:', newBooking);

        io.to('captains').emit('new_ride_available',newBooking);
        socket.emit('ride_request_successfully', newBooking);
    }catch (error) {
        console.error('Error handling ride request:', error);
        socket.emit('error', { message: error.message || 'Error processing ride request' });
    }
});

    socket.on('disconnect', async () => {
        if (socket.userId) {
            try {
                await User.findByIdAndUpdate(socket.userId, {
                    status: 'OFFLINE'
                });
            } catch (error) {
                console.error('Error updating user status:', error);
            }
        }
        console.log('User disconnected:', socket.id);
    });
});

// Routes
app.use('/api/auth', authApiRoutes); // Use the new auth routes for /api/auth prefix
app.use('/api/rides', rideRoutes);
// app.use('/api/users', userRoutes);
app.use('/api/captain', captainRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/video-calls', videoCallRoutes);
app.use('/api/bookings', bookingRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Something went wrong!' });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
    // Close server & exit process
    server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
    // Close server & exit process
    server.close(() => process.exit(1));
});