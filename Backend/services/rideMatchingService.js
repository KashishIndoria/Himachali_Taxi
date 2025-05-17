const Captain = require('../models/captain/captain');
const geoUtils = require('../utils/geoUtils'); // Assuming geoUtils exists and is correct

/**
 * Find nearby drivers who can accept a ride
 * @param {Number} latitude - Pickup latitude
 * @param {Number} longitude - Pickup longitude
 * @param {Number} radius - Search radius in kilometers (default: 5km)
 * @param {String} vehicleType - Type of vehicle required (optional)
 * @returns {Promise<Array>} - Array of nearby captains with distance and ETA
 */
exports.findNearbyDrivers = async (latitude, longitude, radius = 5, vehicleType = null) => {
  try {
    // Create a query for finding nearby captains
    let query = {
      isOnline: true,      // Captain must be online
      isAvailable: true,   // Captain must be available for new rides
      isVerified: true,    // Captain account must be verified (optional, but good practice)
      accountStatus: 'active', // Ensure account is active
      location: { // Use the 'location' field as defined in captain.js
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude] // MongoDB uses [long, lat] format
          },
          $maxDistance: radius * 1000 // Convert km to meters
        }
      }
    };

    // Add vehicle type filter if specified
    if (vehicleType) {
      // Assuming vehicle details are stored like this, adjust if needed
      query['vehicleDetails.type'] = vehicleType; 
    }

    // Find nearby captains, select necessary fields
    const captains = await Captain.find(query)
      .select('_id firstName lastName phone vehicleDetails rating location socketId') // Added socketId
      .limit(10); // Limit the number of drivers initially found

    if (!captains || captains.length === 0) {
        console.log(`No drivers found near ${latitude}, ${longitude} within ${radius}km.`);
        return [];
    }

    console.log(`Found ${captains.length} potential drivers near ${latitude}, ${longitude}.`);

    // Calculate distance and ETA for each captain
    const driversWithDetails = captains.map(captain => {
      let distance = 0;
      let etaMinutes = 0;

      if (captain.location && captain.location.coordinates) {
          // Calculate exact distance using geoUtils
          distance = geoUtils.calculateDistance(
            latitude, longitude,
            captain.location.coordinates[1], // Lat
            captain.location.coordinates[0]  // Long
          );

          // Calculate ETA based on distance (e.g., average speed of 30km/h)
          // Adjust speed based on region or traffic data if available
          const averageSpeedKmh = 30;
          etaMinutes = Math.round((distance / averageSpeedKmh) * 60);
      }

      return {
        _id: captain._id,
        name: `${captain.firstName} ${captain.lastName || ''}`.trim(),
        phone: captain.phone,
        rating: captain.rating || 5, // Default rating if none
        distance: distance.toFixed(2), // Distance in km
        eta: etaMinutes, // Estimated time in minutes
        vehicleDetails: captain.vehicleDetails, // Include vehicle details
        location: captain.location, // Include current location
        socketId: captain.socketId // Include socketId for direct communication if needed later
      };
    });

    // Sort drivers, e.g., by ETA or a combination of factors
    driversWithDetails.sort((a, b) => a.eta - b.eta); // Sort by lowest ETA

    return driversWithDetails.slice(0, 5); // Return the top 5 closest/fastest drivers

  } catch (error) {
    console.error('Error finding nearby drivers:', error);
    // In a production scenario, you might want to throw a more specific error
    // or return an empty array gracefully.
    return []; // Return empty array on error
  }
};

// Remove matchRideWithDriver if it's now handled directly in socket.js
// exports.matchRideWithDriver = async (ride) => { ... };
