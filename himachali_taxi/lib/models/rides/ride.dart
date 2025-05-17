class Ride {
  final String id;
  final String userId;
  String? captainId;
  final Location pickupLocation;
  final Location dropoffLocation;
  String status;
  final double fare;
  final DateTime createdAt;
  DateTime? updatedAt;

  Ride({
    required this.id,
    required this.userId,
    this.captainId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.status = 'requested',
    required this.fare,
    required this.createdAt,
    this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'],
      userId: json['userId'],
      captainId: json['captainId'],
      pickupLocation: Location.fromJson(json['pickupLocation']),
      dropoffLocation: Location.fromJson(json['dropoffLocation']),
      status: json['status'],
      fare: json['fare'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'captainId': captainId,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'status': status,
      'fare': fare,
    };
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
