const Captain = require('../models/captain/captain'); // Adjust path if needed
const logger = require('../utils/logger'); // Optional: for logging

/**
 * Location service for handling driver locations
 */

// In-memory store for captain locations (you'd use Redis in production)
const captainLocations = new Map();
// Default search radius in meters (e.g., 5km)
const DEFAULT_SEARCH_RADIUS_METERS = 5000;

/**
 * Finds captains who are online, available, and within a certain radius of a given point.
 * @param {number} latitude - The latitude of the center point (e.g., pickup location).
 * @param {number} longitude - The longitude of the center point (e.g., pickup location).
 * @param {number} [radiusInMeters=DEFAULT_SEARCH_RADIUS_METERS] - The search radius in meters.
 * @returns {Promise<Array<{_id: string, socketId: string | null, location: object}>>} - A promise that resolves to an array of captain objects containing _id, socketId, and location.
 */
const findNearbyCaptains = async (latitude, longitude, radiusInMeters = DEFAULT_SEARCH_RADIUS_METERS) => {
  if (latitude === undefined || longitude === undefined) {
    logger.error('findNearbyCaptains called without latitude or longitude.');
    return []; // Return empty array if coordinates are missing
  }

  try {
    const nearbyCaptains = await Captain.find({
      isOnline: true,     // Captain must be marked as online
      isAvailable: true,  // Captain must be available for rides
      socketId: { $ne: null }, // Captain must have an active socket connection
      location: {         // Use MongoDB's geospatial query
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude] // GeoJSON order: [longitude, latitude]
          },
          $maxDistance: radiusInMeters // Max distance in meters
        }
      }
      // Optional: Add filters based on vehicle type, rating, etc. later
    })
    // Select only necessary fields
    .select('_id socketId location firstName lastName averageRating vehicleDetails'); // Include fields needed for ride request notification

    logger.info(`Found ${nearbyCaptains.length} nearby available captains within ${radiusInMeters}m of [${longitude}, ${latitude}]`);
    return nearbyCaptains;

  } catch (error) {
    logger.error('Error finding nearby captains:', error);
    return []; // Return empty array on error
  }
};

/**
 * Finds the current socketId for a given captain ID.
 * @param {string} captainId - The ID of the captain.
 * @returns {Promise<string | null>} - A promise that resolves to the socketId string or null if not found/offline.
 */
const findCaptainSocketId = async (captainId) => {
  if (!captainId) {
    logger.warn('findCaptainSocketId called without captainId.');
    return null;
  }
  try {
    // Find the captain and select only the socketId field
    const captain = await Captain.findById(captainId).select('socketId isOnline').lean(); // Use lean for performance if only reading

    if (captain && captain.isOnline && captain.socketId) {
      return captain.socketId;
    } else {
      // Log only if captain exists but is offline or has no socketId
      if (captain) {
         logger.warn(`Captain ${captainId} found but is offline or has no socketId. isOnline: ${captain.isOnline}, socketId: ${captain.socketId}`);
      } else {
         logger.warn(`Captain ${captainId} not found.`);
      }
      return null; // Captain not found, offline, or socketId is null
    }
  } catch (error) {
    logger.error(`Error finding socketId for captain ${captainId}:`, error);
    return null; // Return null on error
  }
};


module.exports = {
  findNearbyCaptains,
  findCaptainSocketId,
  // Remove the old locationService export
};
// The old locationService object and its export below should be removed.
/*
const locationService = {
  // ... old functions ...
};

module.exports = locationService;
*/
const locationService = {
  /**
   * Process captain location update
   * @param {string} captainId - The captain's ID
   * @param {Object} locationData - Location data with lat, lng, etc.
   */
  processCaptainLocation: async (captainId, locationData) => {
    try {
      // Store captain's current location
      captainLocations.set(captainId, {
        ...locationData,
        timestamp: new Date()
      });
      
      // In a real implementation, you might:
      // 1. Calculate if the captain is close to any pickup location
      // 2. Update estimated arrival times
      // 3. Check for geofence triggers
      
      return true;
    } catch (error) {
      console.error('Error processing captain location:', error);
      return false;
    }
  },

  /**
   * Get captain's last known location
   * @param {string} captainId - The captain's ID
   */
  getCaptainLocation: (captainId) => {
    return captainLocations.get(captainId) || null;
  },

  /**
   * Clear location data (useful for testing or when captain logs out)
   * @param {string} captainId - The captain's ID
   */
  clearCaptainLocation: (captainId) => {
    captainLocations.delete(captainId);
  }
};

module.exports = locationService;