/// Represents a ride request received by a captain (driver)
class CaptainRideRequest {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final double passengerRating;

  // Location details
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;

  // Ride details
  final double estimatedFare;
  final double estimatedDistance;
  final int estimatedDuration; // in seconds
  final String vehicleType;
  final String paymentMethod;

  // Request timing
  final DateTime requestTime;
  final DateTime? acceptedTime;
  final DateTime? completedTime;
  final DateTime? cancelledTime;

  // Status tracking
  final String
      status; // new, accepted, in_progress, completed, cancelled, declined
  final String? cancellationReason;

  CaptainRideRequest({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.passengerRating,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.vehicleType,
    required this.paymentMethod,
    required this.requestTime,
    this.acceptedTime,
    this.completedTime,
    this.cancelledTime,
    required this.status,
    this.cancellationReason,
  });

  // Factory constructor to create a CaptainRideRequest from JSON
  factory CaptainRideRequest.fromJson(Map<String, dynamic> json) {
    return CaptainRideRequest(
      id: json['_id'] ?? json['id'] ?? '',
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      passengerRating: (json['passengerRating'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? {},
      dropoffLocation: json['dropoffLocation'] ?? {},
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',
      estimatedFare: (json['estimatedFare'] ?? 0.0).toDouble(),
      estimatedDistance: (json['estimatedDistance'] ?? 0.0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      vehicleType: json['vehicleType'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      requestTime: json['requestTime'] != null
          ? DateTime.parse(json['requestTime'])
          : DateTime.now(),
      acceptedTime: json['acceptedTime'] != null
          ? DateTime.parse(json['acceptedTime'])
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      cancelledTime: json['cancelledTime'] != null
          ? DateTime.parse(json['cancelledTime'])
          : null,
      status: json['status'] ?? 'new',
      cancellationReason: json['cancellationReason'],
    );
  }

  // Convert CaptainRideRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerRating': passengerRating,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'estimatedFare': estimatedFare,
      'estimatedDistance': estimatedDistance,
      'estimatedDuration': estimatedDuration,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'requestTime': requestTime.toIso8601String(),
      'acceptedTime': acceptedTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'cancelledTime': cancelledTime?.toIso8601String(),
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }

  // Create a copy of the request with updated fields
  CaptainRideRequest copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    double? passengerRating,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
    String? pickupAddress,
    String? dropoffAddress,
    double? estimatedFare,
    double? estimatedDistance,
    int? estimatedDuration,
    String? vehicleType,
    String? paymentMethod,
    DateTime? requestTime,
    DateTime? acceptedTime,
    DateTime? completedTime,
    DateTime? cancelledTime,
    String? status,
    String? cancellationReason,
  }) {
    return CaptainRideRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerRating: passengerRating ?? this.passengerRating,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      vehicleType: vehicleType ?? this.vehicleType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      requestTime: requestTime ?? this.requestTime,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      completedTime: completedTime ?? this.completedTime,
      cancelledTime: cancelledTime ?? this.cancelledTime,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Helper methods to update status
  CaptainRideRequest markAsAccepted() {
    return copyWith(
      status: 'accepted',
      acceptedTime: DateTime.now(),
    );
  }

  CaptainRideRequest markAsCompleted() {
    return copyWith(
      status: 'completed',
      completedTime: DateTime.now(),
    );
  }

  CaptainRideRequest markAsCancelled(String reason) {
    return copyWith(
      status: 'cancelled',
      cancellationReason: reason,
      cancelledTime: DateTime.now(),
    );
  }

  CaptainRideRequest markAsDeclined() {
    return copyWith(
      status: 'declined',
    );
  }

  // Calculate time elapsed since request was created
  Duration getElapsedTime() {
    return DateTime.now().difference(requestTime);
  }

  // Check if request is still valid (not too old)
  bool isRequestValid({int maxAgeInSeconds = 60}) {
    return getElapsedTime().inSeconds <= maxAgeInSeconds;
  }
}
