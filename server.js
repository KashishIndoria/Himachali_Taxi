const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const app = express();
const connectDB = require('./config/db');
const {initSocket} = require('./config/socket');
require('dotenv').config();
const http = require('http');
const logger = require('./utils/logger'); // Assuming you have a logger utility

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// //Load env vars
// dotenv.config();

//connect to Database 
connectDB();

// Import routes
const authRoutes = require('./routes/authroutes');
const userRoutes = require('./routes/userroutes');
const captainRoutes = require('./routes/captainroutes');
const locationRoutes = require('./routes/locationroutes');
const uploadRoutes = require('./routes/profileroutes');
const ratingRoutes = require('./routes/ratingroutes');
// const rideRoutes = require('./routes/rideroutes'); // Assuming you have a ride route

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/captains', captainRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/ratings', ratingRoutes);
// app.use('/api/rides', rideRoutes); // Use the ride routes


// Basic route
app.get('/', (req, res) => {
    res.send('Himachali Taxi API is running');
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        status: 'error',
        message: 'Something went wrong!'
    });
});


const server = http.createServer(app);
// Remove socket initialization and handlers from here
// const io = initSocket(server);
// io.on('connection', (socket) => { ... });

const PORT = process.env.PORT || 3000; // Default to 3000 for local dev
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  logger.error(`Unhandled Rejection: \${err.message}`);
  // Close server & exit process (optional but recommended in production)
  // server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
    logger.error(`Uncaught Exception: \${err.message}`);
    // Close server & exit process (optional but recommended in production)
    // server.close(() => process.exit(1));
});