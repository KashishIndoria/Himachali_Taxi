const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  captainId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Captain'
  },
  pickupLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    },
    address: {
      type: String,
      required: true
    }
  },
  dropoffLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    },
    address: {
      type: String,
      required: true
    }
  },
  bookingTime: {
    type: Date,
    default: Date.now
  },
  acceptedTime: {
    type: Date
  },
  completedTime: {
    type: Date
  },
  estimatedFare: {
    type: Number,
    required: true
  },
  actualFare: {
    type: Number
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'inProgress', 'completed', 'cancelled'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'upi'],
    default: 'cash'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'failed'],
    default: 'pending'
  },
  cancellationReason: {
    type: String
  },
  additionalDetails: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

// Index for geospatial queries
bookingSchema.index({ 'pickupLocation': '2dsphere' });
bookingSchema.index({ 'dropoffLocation': '2dsphere' });

// Index for common queries
bookingSchema.index({ userId: 1, status: 1 });
bookingSchema.index({ captainId: 1, status: 1 });

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking; 