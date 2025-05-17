// himachali_taxi/lib/models/ride_model.dart

class Ride {
  final String id;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropLocation;
  final double fare;
  final String status;
  final Map<String, dynamic>? userId; // User details might be populated
  final DateTime? createdAt; // Added createdAt

  // Helper getters for location details
  double? get pickupLat => (pickupLocation['latitude'] as num?)?.toDouble();
  double? get pickupLng => (pickupLocation['longitude'] as num?)?.toDouble();
  String? get pickupAddress => pickupLocation['address'] as String?;

  double? get dropLat => (dropLocation['latitude'] as num?)?.toDouble();
  double? get dropLng => (dropLocation['longitude'] as num?)?.toDouble();
  String? get dropAddress => dropLocation['address'] as String?;

  // Helper getters for user details
  String? get userName => userId?['firstName'] != null
      ? '${userId!['firstName']} ${userId!['lastName'] ?? ''}'.trim()
      : 'N/A';
  String? get userProfileImage => userId?['profileImage'] as String?;
  double? get userRating => (userId?['rating'] as num?)?.toDouble();

  Ride({
    required this.id,
    required this.pickupLocation,
    required this.dropLocation,
    required this.fare,
    required this.status,
    this.userId,
    this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'] as String? ?? '',
      pickupLocation: json['pickupLocation'] as Map<String, dynamic>? ?? {},
      dropLocation: json['dropLocation'] as Map<String, dynamic>? ?? {},
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      userId: json['userId']
          as Map<String, dynamic>?, // Assuming userId is populated object
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      // Map other fields if needed
    );
  }

  // Optional: Add toJson if needed for sending data
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'fare': fare,
      'status': status,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
