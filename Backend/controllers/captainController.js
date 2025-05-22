const Captain = require('../models/captain/captain');
const Ride = require('../models/ride/ride');
const asyncHandler = require('express-async-handler');
const { getIO } = require('../config/socket'); // Import getIO

// @desc    Get captain profile
// @route   GET /api/captains/profile/:captainId
// @access  Private
const getCaptainProfile = asyncHandler(async (req, res) => {
  const captain = await Captain.findById(req.params.captainId)
    .select('-password')
    .lean();

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  res.json({
    success: true,
    data: captain
  });
});

// @desc    Update captain profile
// @route   PUT /api/captains/profile
// @access  Private
const updateCaptainProfile = asyncHandler(async (req, res) => {
  const { firstName, lastName, phone, vehicleDetails, drivingLicense } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  // Validate input data
  if (firstName && (firstName.length < 2 || firstName.length > 50)) {
    res.status(400);
    throw new Error('First name must be between 2 and 50 characters');
  }

  if (lastName && (lastName.length < 2 || lastName.length > 50)) {
    res.status(400);
    throw new Error('Last name must be between 2 and 50 characters');
  }

  if (phone && !/^\+?[1-9]\d{9,14}$/.test(phone)) {
    res.status(400);
    throw new Error('Invalid phone number format');
  }

  // Update fields
  if (firstName) captain.firstName = firstName;
  if (lastName) captain.lastName = lastName;
  if (phone) captain.phone = phone;
  if (vehicleDetails) {
    // Validate vehicle details
    if (!vehicleDetails.model || !vehicleDetails.plateNumber) {
      res.status(400);
      throw new Error('Vehicle model and plate number are required');
    }
    captain.vehicleDetails = vehicleDetails;
  }
  if (drivingLicense) {
    // Validate driving license
    if (!drivingLicense.number || !drivingLicense.expiryDate) {
      res.status(400);
      throw new Error('License number and expiry date are required');
    }
    captain.drivingLicense = drivingLicense;
  }

  const updatedCaptain = await captain.save();
  
  const io = getIO(); // Get io instance
  // Emit profile update event
  io.emit('captainProfileUpdated', {
    captainId: updatedCaptain._id,
    profile: updatedCaptain
  });

  res.json({
    success: true,
    data: updatedCaptain
  });
});

// @desc    Update profile image
// @route   PUT /api/captains/update-profile-image
// @access  Private
const updateProfileImage = asyncHandler(async (req, res) => {
  const { profileImageUrl } = req.body;

  if (!profileImageUrl) {
    res.status(400);
    throw new Error('Profile image URL is required');
  }

  // Validate URL format
  try {
    new URL(profileImageUrl);
  } catch (error) {
    res.status(400);
    throw new Error('Invalid image URL format');
  }

  // Validate file extension
  const validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
  const hasValidExtension = validExtensions.some(ext => 
    profileImageUrl.toLowerCase().endsWith(ext)
  );

  if (!hasValidExtension) {
    res.status(400);
    throw new Error('Invalid image format. Supported formats: JPG, JPEG, PNG, GIF');
  }

  const captain = await Captain.findById(req.user._id);
  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  captain.profileImage = profileImageUrl;
  const updatedCaptain = await captain.save();

  const io = getIO(); // Get io instance
  // Emit profile image update event
  io.emit('captainProfileImageUpdated', {
    captainId: updatedCaptain._id,
    profileImage: updatedCaptain.profileImage
  });

  res.json({
    success: true,
    data: {
      profileImage: updatedCaptain.profileImage
    }
  });
});

// @desc    Get captain status
// @route   GET /api/captains/status
// @access  Private
const getCaptainStatus = asyncHandler(async (req, res) => {
  const captain = await Captain.findById(req.user._id)
    .select('isAvailable isOnline currentRide status')
    .lean();

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  res.json({
    success: true,
    data: captain
  });
});

// @desc    Toggle availability
// @route   POST /api/captains/toggle-availability
// @access  Private
const toggleAvailability = asyncHandler(async (req, res) => {
  const { isAvailable } = req.body;

  if (typeof isAvailable !== 'boolean') {
    res.status(400);
    throw new Error('isAvailable must be a boolean value');
  }

  const captain = await Captain.findById(req.user._id);
  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  // Check if captain can toggle availability
  if (captain.currentRide && isAvailable) {
    res.status(400);
    throw new Error('Cannot set availability while on a ride');
  }

  captain.isAvailable = isAvailable;
  const updatedCaptain = await captain.save();

  const io = getIO(); // Get io instance
  // Emit availability update event
  io.emit('captainAvailabilityUpdated', {
    captainId: updatedCaptain._id,
    isAvailable: updatedCaptain.isAvailable
  });

  res.json({
    success: true,
    data: {
      isAvailable: updatedCaptain.isAvailable
    }
  });
});

// @desc    Update location
// @route   POST /api/captains/update-location
// @access  Private
const updateLocation = asyncHandler(async (req, res) => {
  const { latitude, longitude, heading, speed } = req.body;

  // Validate required fields
  if (!latitude || !longitude) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }

  // Validate coordinate ranges
  if (latitude < -90 || latitude > 90) {
    res.status(400);
    throw new Error('Invalid latitude value');
  }
  if (longitude < -180 || longitude > 180) {
    res.status(400);
    throw new Error('Invalid longitude value');
  }

  // Validate optional fields
  if (heading !== undefined && (heading < 0 || heading > 360)) {
    res.status(400);
    throw new Error('Heading must be between 0 and 360 degrees');
  }
  if (speed !== undefined && speed < 0) {
    res.status(400);
    throw new Error('Speed cannot be negative');
  }

  const captain = await Captain.findById(req.user._id);
  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  captain.location = {
    type: 'Point',
    coordinates: [longitude, latitude]
  };
  if (heading !== undefined) captain.heading = heading;
  if (speed !== undefined) captain.speed = speed;

  const updatedCaptain = await captain.save();

  const io = getIO(); // Get io instance
  // Emit location update event
  io.emit('captainLocationUpdated', {
    captainId: updatedCaptain._id,
    location: updatedCaptain.location,
    heading: updatedCaptain.heading,
    speed: updatedCaptain.speed
  });

  res.json({
    success: true,
    data: {
      location: updatedCaptain.location,
      heading: updatedCaptain.heading,
      speed: updatedCaptain.speed
    }
  });
});

// @desc    Get ride history
// @route   GET /api/captains/rides
// @access  Private
const getRideHistory = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const rides = await Ride.find({ captain: req.user._id })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('user', 'firstName lastName phone')
    .lean();

  const total = await Ride.countDocuments({ captain: req.user._id });

  res.json({
    success: true,
    data: {
      rides,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    }
  });
});

// @desc    Get earnings
// @route   GET /api/captains/earnings
// @access  Private
const getEarnings = asyncHandler(async (req, res) => {
  const { period = 'all' } = req.query;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  let startDate;
  const now = new Date();

  switch (period) {
    case 'today':
      startDate = new Date(now.setHours(0, 0, 0, 0));
      break;
    case 'week':
      startDate = new Date(now.setDate(now.getDate() - 7));
      break;
    case 'month':
      startDate = new Date(now.setMonth(now.getMonth() - 1));
      break;
    case 'year':
      startDate = new Date(now.setFullYear(now.getFullYear() - 1));
      break;
    default:
      startDate = new Date(0); // Beginning of time
  }

  const earnings = await Ride.aggregate([
    {
      $match: {
        captain: captain._id,
        status: 'completed',
        createdAt: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: null,
        totalEarnings: { $sum: '$fare' },
        totalRides: { $sum: 1 },
        averageFare: { $avg: '$fare' }
      }
    }
  ]);

  res.json({
    success: true,
    data: {
      period,
      ...earnings[0] || { totalEarnings: 0, totalRides: 0, averageFare: 0 }
    }
  });
});

// @desc    Get available rides
// @route   GET /api/captains/available-rides
// @access  Private
const getAvailableRides = asyncHandler(async (req, res) => {
  const captain = await Captain.findById(req.user._id);
  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  if (!captain.isAvailable) {
    res.status(400);
    throw new Error('Captain is not available for rides');
  }

  const rides = await Ride.find({
    status: 'pending',
    'pickupLocation': {
      $near: {
        $geometry: captain.location,
        $maxDistance: 5000 // 5km radius
      }
    }
  })
  .sort({ createdAt: 1 })
  .limit(10)
  .populate('user', 'firstName lastName phone')
  .lean();

  res.json({
    success: true,
    data: rides
  });
});

// @desc    Accept ride request
// @route   POST /api/captains/accept-ride
// @access  Private
const acceptRideRequest = asyncHandler(async (req, res) => {
  const { rideId } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  if (!captain.isAvailable) {
    res.status(400);
    throw new Error('Captain is not available for rides');
  }

  if (captain.currentRide) {
    res.status(400);
    throw new Error('Captain is already on a ride');
  }

  const ride = await Ride.findById(rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.status !== 'pending') {
    res.status(400);
    throw new Error('Ride is no longer available');
  }

  ride.captain = captain._id;
  ride.status = 'accepted';
  ride.acceptedAt = new Date();
  await ride.save();

  captain.currentRide = ride._id;
  captain.isAvailable = false;
  await captain.save();

  const io = getIO(); // Get io instance
  // Emit ride accepted event
  io.emit('rideAccepted', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user
  });

  res.json({
    success: true,
    data: ride
  });
});

// @desc    Decline ride request
// @route   POST /api/captains/decline-ride/:rideId
// @access  Private
const declineRideRequest = asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  const ride = await Ride.findById(req.params.rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.status !== 'pending') {
    res.status(400);
    throw new Error('Ride is no longer available');
  }

  ride.status = 'declined';
  ride.declinedAt = new Date();
  ride.declineReason = reason || 'Declined by captain';
  await ride.save();

  const io = getIO(); // Get io instance
  // Emit ride declined event
  io.emit('rideDeclined', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user,
    reason: ride.declineReason
  });

  res.json({
    success: true,
    message: 'Ride declined successfully'
  });
});

// @desc    Complete ride
// @route   POST /api/captains/complete-ride
// @access  Private
const completeRide = asyncHandler(async (req, res) => {
  const { rideId, finalFare, distance, duration } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  const ride = await Ride.findById(rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.captain.toString() !== captain._id.toString()) {
    res.status(403);
    throw new Error('Not authorized to complete this ride');
  }

  if (ride.status !== 'in_progress') {
    res.status(400);
    throw new Error('Ride is not in progress');
  }

  ride.status = 'completed';
  ride.completedAt = new Date();
  ride.finalFare = finalFare;
  if (distance) ride.distance = distance;
  if (duration) ride.duration = duration;
  await ride.save();

  captain.currentRide = null;
  captain.isAvailable = true;
  await captain.save();

  const io = getIO(); // Get io instance
  // Emit ride completed event
  io.emit('rideCompleted', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user,
    finalFare
  });

  res.json({
    success: true,
    data: ride
  });
});

// @desc    Cancel ride
// @route   POST /api/captains/cancel-ride
// @access  Private
const cancelRideByDriver = asyncHandler(async (req, res) => {
  const { rideId, reason } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  const ride = await Ride.findById(rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.captain.toString() !== captain._id.toString()) {
    res.status(403);
    throw new Error('Not authorized to cancel this ride');
  }

  if (!['accepted', 'in_progress'].includes(ride.status)) {
    res.status(400);
    throw new Error('Ride cannot be cancelled in its current state');
  }

  ride.status = 'cancelled';
  ride.cancelledAt = new Date();
  ride.cancelReason = reason;
  await ride.save();

  captain.currentRide = null;
  captain.isAvailable = true;
  await captain.save();

  const io = getIO(); // Get io instance
  // Emit ride cancelled event
  io.emit('rideCancelled', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user,
    reason
  });

  res.json({
    success: true,
    message: 'Ride cancelled successfully'
  });
});

// @desc    Mark as arrived
// @route   POST /api/captains/arrive
// @access  Private
const markAsArrived = asyncHandler(async (req, res) => {
  const { rideId } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  const ride = await Ride.findById(rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.captain.toString() !== captain._id.toString()) {
    res.status(403);
    throw new Error('Not authorized to update this ride');
  }

  if (ride.status !== 'accepted') {
    res.status(400);
    throw new Error('Ride is not in accepted state');
  }

  ride.status = 'arrived';
  ride.arrivedAt = new Date();
  await ride.save();

  const io = getIO(); // Get io instance
  // Emit arrived event
  io.emit('captainArrived', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user
  });

  res.json({
    success: true,
    data: ride
  });
});

// @desc    Start ride
// @route   POST /api/captains/start-ride
// @access  Private
const startRide = asyncHandler(async (req, res) => {
  const { rideId } = req.body;
  const captain = await Captain.findById(req.user._id);

  if (!captain) {
    res.status(404);
    throw new Error('Captain not found');
  }

  const ride = await Ride.findById(rideId);
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }

  if (ride.captain.toString() !== captain._id.toString()) {
    res.status(403);
    throw new Error('Not authorized to update this ride');
  }

  if (ride.status !== 'arrived') {
    res.status(400);
    throw new Error('Ride is not in arrived state');
  }

  ride.status = 'in_progress';
  ride.startedAt = new Date();
  await ride.save();

  const io = getIO(); // Get io instance
  // Emit ride started event
  io.emit('rideStarted', {
    rideId: ride._id,
    captainId: captain._id,
    userId: ride.user
  });

  res.json({
    success: true,
    data: ride
  });
});

module.exports = {
  getCaptainProfile,
  updateCaptainProfile,
  updateProfileImage,
  getCaptainStatus,
  toggleAvailability,
  updateLocation,
  getRideHistory,
  getEarnings,
  getAvailableRides,
  acceptRideRequest,
  declineRideRequest,
  completeRide,
  cancelRideByDriver,
  markAsArrived,
  startRide
};
