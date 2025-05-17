import 'dart:io' show Platform; // Import Platform
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final Location _location = Location();
  LocationData? _currentLocation;
  final String _host =
      '192.168.177.195'; // Use the computer's local network IP directly

  Future<bool> requestPermission() async {
    try {
      final permission = await _location.requestPermission();

      // Also check if service is enabled
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        final isEnabled = await _location.requestService();
        if (!isEnabled) {
          return false;
        }
      }

      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      _currentLocation = await _location.getLocation();
      return _currentLocation;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<LocationData> getLocationStream() {
    return _location.onLocationChanged;
  }

  Future<void> startLocationUpdates(
      {required String userId,
      required String role,
      required String? rideId}) async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      _location.onLocationChanged.listen((LocationData currentLocation) {
        _updateLocationToServer(
            userId: userId,
            role: role,
            rideId: rideId,
            latitude: currentLocation.latitude!,
            longitude: currentLocation.longitude!);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _updateLocationToServer(
      {required String userId,
      required String role,
      required String? rideId,
      required double latitude,
      required double longitude}) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/location/update'), // Use host variable
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'role': role,
          'rideId': rideId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error updating location');
      }

      final data = json.decode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void stopLocationUpdates() {
    _location.enableBackgroundMode(enable: false);
  }
}
