import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  final String id;
  final String passengerId;
  final String? captainId;
  final String status;
  final Location pickup;
  final Location dropoff;
  LatLng? currentLocation;
  final double distance;
  final double duration;
  final Fare fare;
  final Payment payment;
  final Rating? passengerRating;
  final Rating? captainRating;
  final RideTimestamps timestamps;

  Ride({
    required this.id,
    required this.passengerId,
    this.captainId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    this.currentLocation,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.payment,
    this.passengerRating,
    this.captainRating,
    required this.timestamps,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'],
      passengerId: json['passenger'],
      captainId: json['captain'],
      status: json['status'],
      pickup: Location.fromJson(json['pickup']),
      dropoff: Location.fromJson(json['dropoff']),
      currentLocation: json['currentLocation'] != null
          ? LatLng(
              json['currentLocation']['coordinates'][1],
              json['currentLocation']['coordinates'][0],
            )
          : null,
      distance: json['distance']?.toDouble() ?? 0.0,
      duration: json['duration']?.toDouble() ?? 0.0,
      fare: Fare.fromJson(json['fare'] ?? {}),
      payment: Payment.fromJson(json['payment'] ?? {}),
      passengerRating: json['rating']?['passenger'] != null
          ? Rating.fromJson(json['rating']['passenger'])
          : null,
      captainRating: json['rating']?['captain'] != null
          ? Rating.fromJson(json['rating']['captain'])
          : null,
      timestamps: RideTimestamps.fromJson(json['timestamps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'passenger': passengerId,
      'captain': captainId,
      'status': status,
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
      'currentLocation': currentLocation != null
          ? {
              'type': 'Point',
              'coordinates': [
                currentLocation!.longitude,
                currentLocation!.latitude
              ]
            }
          : null,
      'distance': distance,
      'duration': duration,
      'fare': fare.toJson(),
      'payment': payment.toJson(),
      'rating': {
        'passenger': passengerRating?.toJson(),
        'captain': captainRating?.toJson(),
      },
      'timestamps': timestamps.toJson(),
    };
  }
}

class Location {
  final LatLng location;
  final String address;

  Location({required this.location, required this.address});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      location: LatLng(
        json['location']['coordinates'][1],
        json['location']['coordinates'][0],
      ),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude]
      },
      'address': address,
    };
  }
}

class Fare {
  final double base;
  final double distance;
  final double time;
  final double total;

  Fare({
    required this.base,
    required this.distance,
    required this.time,
    required this.total,
  });

  factory Fare.fromJson(Map<String, dynamic> json) {
    return Fare(
      base: json['base']?.toDouble() ?? 0.0,
      distance: json['distance']?.toDouble() ?? 0.0,
      time: json['time']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': base,
      'distance': distance,
      'time': time,
      'total': total,
    };
  }
}

class Payment {
  final String status;
  final String method;
  final String? transactionId;

  Payment({
    required this.status,
    required this.method,
    this.transactionId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      status: json['status'] ?? 'PENDING',
      method: json['method'] ?? 'CASH',
      transactionId: json['transactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'method': method,
      'transactionId': transactionId,
    };
  }
}

class Rating {
  final double rating;
  final String? comment;

  Rating({required this.rating, this.comment});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }
}

class RideTimestamps {
  final DateTime requested;
  final DateTime? accepted;
  final DateTime? arrived;
  final DateTime? started;
  final DateTime? completed;
  final DateTime? cancelled;

  RideTimestamps({
    required this.requested,
    this.accepted,
    this.arrived,
    this.started,
    this.completed,
    this.cancelled,
  });

  factory RideTimestamps.fromJson(Map<String, dynamic> json) {
    return RideTimestamps(
      requested: DateTime.parse(json['requested']),
      accepted:
          json['accepted'] != null ? DateTime.parse(json['accepted']) : null,
      arrived: json['arrived'] != null ? DateTime.parse(json['arrived']) : null,
      started: json['started'] != null ? DateTime.parse(json['started']) : null,
      completed:
          json['completed'] != null ? DateTime.parse(json['completed']) : null,
      cancelled:
          json['cancelled'] != null ? DateTime.parse(json['cancelled']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requested': requested.toIso8601String(),
      'accepted': accepted?.toIso8601String(),
      'arrived': arrived?.toIso8601String(),
      'started': started?.toIso8601String(),
      'completed': completed?.toIso8601String(),
      'cancelled': cancelled?.toIso8601String(),
    };
  }
}
