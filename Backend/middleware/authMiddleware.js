const jwt = require('jsonwebtoken');
const User = require('../models/user/User');
const Captain = require('../models/captain/captain');
const logger = require('../utils/logger'); // Assuming logger is configured

/**
 * Authentication middleware to verify JWT tokens
 * Works for both users and captains
 */
module.exports = async function(req, res, next) {
  // Get token from header
  const token = req.header('Authorization')?.replace('Bearer ', '');

  // Check if no token
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
    // Ensure token has necessary info
    if (!decoded.id || !decoded.role) {
      // Use logger if available and configured
      if (typeof logger !== 'undefined' && logger.warn) {
        logger.warn('JWT decoded payload missing id or role:', decoded);
      } else {
        console.warn('JWT decoded payload missing id or role:', decoded);
      }
      return res.status(401).json({ message: 'Invalid token payload' });
    }

    // Check if token has expired (incorporating from original code)
    const currentTimestamp = Math.floor(Date.now() / 1000);
    if (decoded.exp && decoded.exp < currentTimestamp) {
      // Use logger if available and configured
      if (typeof logger !== 'undefined' && logger.warn) {
        logger.warn(`Token expired for user/captain ID: ${decoded.id}`);
      } else {
        console.warn(`Token expired for user/captain ID: ${decoded.id}`);
      }
      return res.status(401).json({ message: 'Token has expired' });
    }

    // Fetch user/captain from DB based on role in token
    let userOrCaptain;
    if (decoded.role === 'captain') {
      // Select only necessary fields, like _id, unless others are needed downstream
      userOrCaptain = await Captain.findById(decoded.id).select('_id');
    } else if (decoded.role === 'user') {
      // Select only necessary fields
      userOrCaptain = await User.findById(decoded.id).select('_id');
    } else {
      // Use logger if available and configured
      if (typeof logger !== 'undefined' && logger.warn) {
        logger.warn(`JWT decoded with unknown role: ${decoded.role} for ID: ${decoded.id}`);
      } else {
        console.warn(`JWT decoded with unknown role: ${decoded.role} for ID: ${decoded.id}`);
      }
      return res.status(401).json({ message: 'Invalid user role in token' });
    }

    if (!userOrCaptain) {
      // Use logger if available and configured
      if (typeof logger !== 'undefined' && logger.warn) {
        logger.warn(`User/Captain not found for ID: ${decoded.id} with role: ${decoded.role}`);
      } else {
        console.warn(`User/Captain not found for ID: ${decoded.id} with role: ${decoded.role}`);
      }
      return res.status(401).json({ message: 'Invalid token - user/captain not found' });
    }

    // Attach consistent user info object to request, as per the 'protect' example
    req.user = {
      id: userOrCaptain._id.toString(), // Ensure it's a string ID
      role: decoded.role // Get role from token payload
      // Add other fields from userOrCaptain if needed downstream, e.g., name: userOrCaptain.name
    };

    // The original req.isCaptain is now implicitly handled by req.user.role === 'captain'

    next(); // Proceed to next middleware
  } catch (err) {
    console.error('Auth middleware error:', err);
    res.status(401).json({ message: 'Token is not valid' });
  }
};