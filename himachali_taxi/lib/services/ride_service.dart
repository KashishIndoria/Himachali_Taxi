import 'dart:async';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride.dart';
import 'socket_service.dart';

class RideService {
  final Dio _dio;
  final SocketService _socketService;
  final _rideUpdateController = StreamController<Ride>.broadcast();

  RideService(this._dio, this._socketService) {
    _setupSocketListeners();
  }

  Stream<Ride> get rideUpdates => _rideUpdateController.stream;

  void _setupSocketListeners() {
    _socketService.rideStatusUpdates.listen((data) {
      if (data != null) {
        final ride = Ride.fromJson(data);
        _rideUpdateController.add(ride);
      }
    });

    _socketService.captainLocationUpdates.listen((data) {
      if (data != null && data['rideId'] != null) {
        // Update captain location in the ride object
        _updateCaptainLocation(
            data['rideId'],
            LatLng(data['location']['coordinates'][1],
                data['location']['coordinates'][0]));
      }
    });
  }

  // Book a new ride
  Future<Ride> bookRide({
    required LatLng pickup,
    required String pickupAddress,
    required LatLng dropoff,
    required String dropoffAddress,
  }) async {
    try {
      final response = await _dio.post('/api/rides/book', data: {
        'pickup': {
          'location': {
            'type': 'Point',
            'coordinates': [pickup.longitude, pickup.latitude]
          },
          'address': pickupAddress
        },
        'dropoff': {
          'location': {
            'type': 'Point',
            'coordinates': [dropoff.longitude, dropoff.latitude]
          },
          'address': dropoffAddress
        }
      });

      return Ride.fromJson(response.data['ride']);
    } catch (e) {
      print('Error booking ride: $e');
      rethrow;
    }
  }

  // Get ride history
  Future<List<Ride>> getRideHistory({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/api/rides/history',
        queryParameters: {'page': page, 'limit': limit},
      );

      return (response.data['rides'] as List)
          .map((ride) => Ride.fromJson(ride))
          .toList();
    } catch (e) {
      print('Error fetching ride history: $e');
      rethrow;
    }
  }

  // Get current active ride
  Future<Ride?> getCurrentRide() async {
    try {
      final response = await _dio.get('/api/rides/current');
      if (response.data['ride'] != null) {
        return Ride.fromJson(response.data['ride']);
      }
      return null;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 404) {
        return null;
      }
      print('Error fetching current ride: $e');
      rethrow;
    }
  }

  // Update ride status (for captain)
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _dio.put('/api/rides/$rideId/status', data: {
        'status': status,
      });
    } catch (e) {
      print('Error updating ride status: $e');
      rethrow;
    }
  }

  // Update captain's location
  Future<void> updateLocation(String rideId, LatLng location) async {
    try {
      await _dio.put('/api/rides/$rideId/status', data: {
        'currentLocation': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude]
        }
      });
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  // Helper method to update captain location in the ride object
  void _updateCaptainLocation(String rideId, LatLng location) {
    // Notify listeners about the location update
    getCurrentRide().then((ride) {
      if (ride != null && ride.id == rideId) {
        ride.currentLocation = location;
        _rideUpdateController.add(ride);
      }
    });
  }

  void dispose() {
    _rideUpdateController.close();
  }
}
