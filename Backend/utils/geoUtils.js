/**
 * Geolocation utilities for distance calculations and other geographic functions
 */

/**
 * Calculate the distance between two points using the Haversine formula
 * @param {Number} lat1 - Latitude of first point
 * @param {Number} lon1 - Longitude of first point
 * @param {Number} lat2 - Latitude of second point
 * @param {Number} lon2 - Longitude of second point
 * @returns {Number} - Distance in kilometers
 */
exports.calculateDistance = (lat1, lon1, lat2, lon2) => {
    // Radius of the Earth in kilometers
    const R = 6371;
    
    // Convert latitude and longitude from degrees to radians
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    
    // Haversine formula
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c; // Distance in kilometers
    
    return distance;
  };
  
  /**
   * Convert degrees to radians
   * @param {Number} deg - Degrees
   * @returns {Number} - Radians
   */
  function deg2rad(deg) {
    return deg * (Math.PI/180);
  }
  
  /**
   * Calculate the estimated time of arrival (ETA) based on distance and speed
   * @param {Number} distanceKm - Distance in kilometers
   * @param {Number} speedKmh - Speed in kilometers per hour (default: 30 km/h)
   * @returns {Number} - Time in minutes
   */
  exports.calculateETA = (distanceKm, speedKmh = 30) => {
    const timeHours = distanceKm / speedKmh;
    return Math.round(timeHours * 60); // Convert to minutes
  };
  
  /**
   * Check if a point is within a specified radius of another point
   * @param {Number} centerLat - Latitude of center point
   * @param {Number} centerLon - Longitude of center point
   * @param {Number} pointLat - Latitude of point to check
   * @param {Number} pointLon - Longitude of point to check
   * @param {Number} radiusKm - Radius in kilometers
   * @returns {Boolean} - True if point is within radius
   */
  exports.isPointWithinRadius = (centerLat, centerLon, pointLat, pointLon, radiusKm) => {
    const distance = this.calculateDistance(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
  };
  
  /**
   * Get a bounding box around a point (used for simpler database queries)
   * @param {Number} centerLat - Latitude of center point
   * @param {Number} centerLon - Longitude of center point
   * @param {Number} radiusKm - Radius in kilometers
   * @returns {Object} - Bounding box with min/max lat/lon
   */
  exports.getBoundingBox = (centerLat, centerLon, radiusKm) => {
    // Approximate degrees per kilometer at the equator
    const kmInLongitudeDegree = 111.32 * Math.cos(deg2rad(centerLat));
    const kmInLatitudeDegree = 110.574;
    
    const latChange = radiusKm / kmInLatitudeDegree;
    const lonChange = radiusKm / kmInLongitudeDegree;
    
    return {
      minLat: centerLat - latChange,
      maxLat: centerLat + latChange,
      minLon: centerLon - lonChange,
      maxLon: centerLon + lonChange
    };
  };
  
  /**
   * Create a GeoJSON point
   * @param {Number} longitude - Longitude
   * @param {Number} latitude - Latitude
   * @returns {Object} - GeoJSON Point object
   */
  exports.createGeoPoint = (longitude, latitude) => {
    return {
      type: 'Point',
      coordinates: [longitude, latitude]
    };
  };