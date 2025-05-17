import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himachali_taxi/models/rides/ride.dart';

class RideUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final double? averageRating;
  final String? profileImage;

  RideUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.averageRating,
    this.profileImage,
  });

  factory RideUser.fromJson(Map<String, dynamic> json) {
    return RideUser(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      profileImage: json['profile_image'] as String?,
    );
  }

  String get fullName {
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
}

class RideLocation {
  final LatLng coordinates;
  final String? address;

  RideLocation({
    required this.coordinates,
    this.address,
  });

  factory RideLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null ||
        json['coordinates'] == null ||
        json['coordinates'].length != 2) {
      // Handle invalid location data, maybe return a default or throw error
      throw FormatException('Invalid location data format: $json');
    }
    // Coordinates are [longitude, latitude] from backend
    final List<dynamic> coords = json['coordinates'];
    return RideLocation(
      coordinates: LatLng(coords[1].toDouble(),
          coords[0].toDouble()), // LatLng(latitude, longitude)
      address: json['address'],
    );
  }
}

class RideRequest {
  final String id;
  final RideUser user;
  final RideLocation pickupLocation;
  final RideLocation dropoffLocation;
  final String status; // e.g., "pending", "accepted", "completed", etc.
  final DateTime requestedAt; // Estimated fare for the ride
  final double? fareEstimate; // Estimated fare for the ride

  RideRequest({
    required this.id,
    required this.user,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.requestedAt,
    required this.fareEstimate,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      user: RideUser.fromJson(json['user']),
      pickupLocation: RideLocation.fromJson(json['pickup_location']),
      dropoffLocation: RideLocation.fromJson(json['dropoff_location']),
      status: json['status'] as String,
      requestedAt:
          DateTime.tryParse(json['requestedAt'] ?? '') ?? DateTime.now(),
      fareEstimate: (json['fare_estimate'] as num?)?.toDouble(),
    );
  }
}
