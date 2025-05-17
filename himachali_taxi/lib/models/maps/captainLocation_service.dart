import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform; // Import Platform
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CaptainLocationService {
  final String captainId;
  final String? token;
  final IO.Socket socket;

  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // Last known location
  LocationData? lastLocation;

  // Update frequency in seconds
  final int updateInterval;

  final String _host =
      '192.168.177.195'; // Use the computer's local network IP directly

  CaptainLocationService({
    required this.captainId,
    required this.token,
    required this.socket,
    this.updateInterval = 10, // Default to 10 seconds
  });

  Future<void> init() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      // Check if location service is enabled
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }
      }

      // Check location permission
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission not granted');
        }
      }

      // Configure location settings
      location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: updateInterval * 1000, // Convert to milliseconds
        distanceFilter: 10, // Minimum distance (meters) to trigger updates
      );

      // Get initial location
      lastLocation = await location.getLocation();

      // Start location tracking
      startTracking();
    } catch (e) {
      print('Error initializing location service: $e');
      rethrow;
    }
  }

  void startTracking() {
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      lastLocation = currentLocation;

      // Update location on server
      _updateLocationOnServer(currentLocation);

      // Emit location update via socket
      socket.emit('updateLocation', {
        'captainId': captainId,
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'heading': currentLocation.heading,
        'speed': currentLocation.speed,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _updateLocationOnServer(LocationData locationData) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/update-location'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'heading': locationData.heading,
          'speed': locationData.speed,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        print('Server location update failed: ${response.body}');
      }
    } catch (e) {
      print('Error updating location on server: $e');
    }
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // Get formatted CameraPosition for Google Maps
  CameraPosition getCameraPosition() {
    return CameraPosition(
      target: LatLng(
        lastLocation?.latitude ?? 0,
        lastLocation?.longitude ?? 0,
      ),
      zoom: 16.0,
      bearing: lastLocation?.heading ?? 0,
    );
  }

  // Get a marker for the current location
  Marker getCurrentLocationMarker() {
    return Marker(
      markerId: MarkerId('currentLocation'),
      position: LatLng(
        lastLocation?.latitude ?? 0,
        lastLocation?.longitude ?? 0,
      ),
      rotation: lastLocation?.heading ?? 0,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );
  }

  void dispose() {
    stopTracking();
  }
}
