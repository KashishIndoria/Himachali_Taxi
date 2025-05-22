import 'package:google_maps_flutter/google_maps_flutter.dart';

enum BookingStatus { pending, accepted, inProgress, completed, cancelled }

class Booking {
  final String id;
  final String userId;
  final String? captainId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime bookingTime;
  final DateTime? acceptedTime;
  final DateTime? completedTime;
  final double estimatedFare;
  final double? actualFare;
  final BookingStatus status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? cancellationReason;
  final Map<String, dynamic>? additionalDetails;

  Booking({
    required this.id,
    required this.userId,
    this.captainId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.bookingTime,
    this.acceptedTime,
    this.completedTime,
    required this.estimatedFare,
    this.actualFare,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.cancellationReason,
    this.additionalDetails,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'],
      captainId: json['captainId'],
      pickupLocation: LatLng(
        json['pickupLocation']['latitude'],
        json['pickupLocation']['longitude'],
      ),
      dropoffLocation: LatLng(
        json['dropoffLocation']['latitude'],
        json['dropoffLocation']['longitude'],
      ),
      pickupAddress: json['pickupAddress'],
      dropoffAddress: json['dropoffAddress'],
      bookingTime: DateTime.parse(json['bookingTime']),
      acceptedTime: json['acceptedTime'] != null
          ? DateTime.parse(json['acceptedTime'])
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      estimatedFare: json['estimatedFare'].toDouble(),
      actualFare: json['actualFare']?.toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${json['status']}',
      ),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      cancellationReason: json['cancellationReason'],
      additionalDetails: json['additionalDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'captainId': captainId,
      'pickupLocation': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'latitude': dropoffLocation.latitude,
        'longitude': dropoffLocation.longitude,
      },
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'bookingTime': bookingTime.toIso8601String(),
      'acceptedTime': acceptedTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'cancellationReason': cancellationReason,
      'additionalDetails': additionalDetails,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? captainId,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    String? pickupAddress,
    String? dropoffAddress,
    DateTime? bookingTime,
    DateTime? acceptedTime,
    DateTime? completedTime,
    double? estimatedFare,
    double? actualFare,
    BookingStatus? status,
    String? paymentMethod,
    String? paymentStatus,
    String? cancellationReason,
    Map<String, dynamic>? additionalDetails,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      captainId: captainId ?? this.captainId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      bookingTime: bookingTime ?? this.bookingTime,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      completedTime: completedTime ?? this.completedTime,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
    );
  }
}
