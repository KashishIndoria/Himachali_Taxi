const calculateDistance = (point1, point2) => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(point2[0] - point1[0]);
  const dLon = toRad(point2[1] - point1[1]);
  const lat1 = toRad(point1[0]);
  const lat2 = toRad(point2[0]);

  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;

  return distance; // Returns distance in kilometers
};

const toRad = (value) => {
  return value * Math.PI / 180;
};

const isWithinRadius = (point1, point2, radiusKm) => {
  const distance = calculateDistance(point1, point2);
  return distance <= radiusKm;
};

module.exports = {
  calculateDistance,
  isWithinRadius
}; 