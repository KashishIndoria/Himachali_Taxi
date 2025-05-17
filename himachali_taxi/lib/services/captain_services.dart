// himachali_taxi/lib/services/captain_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:http/http.dart' as http;
import '../models/ride_model.dart';
import 'package:location/location.dart' as loc;
import '../utils/sf_manager.dart'; // Import SfManager

class CaptainService {
  // Helper to get Base URL from .env
  String _getBaseUrl() {
    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      // Fallback or error handling
      print("ERROR: BASE_URL not found in .env file.");
      // You might want to throw an exception or return a default URL
      // For now, let's throw an exception as it's critical
      throw Exception("BASE_URL not configured in .env file.");
    }
    return baseUrl;
  }

  // Fetches the authentication token using SfManager
  Future<String?> _getToken() async {
    return await SfManager.getToken(); // Use SfManager with the correct key
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Get available rides near the captain
  Future<List<Ride>> getAvailableRides() async {
    final token = await _getToken();
    if (token == null) {
      // This exception should now only be thrown if SfManager.getToken() returns null
      throw Exception('Authentication token not found');
    }
    final baseUrl = _getBaseUrl(); // Get base URL from .env

    final response = await http.get(
      Uri.parse('$baseUrl/api/captains/available-rides'), // Use variable
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true && responseBody['data'] != null) {
        List<dynamic> rideData = responseBody['data'];
        // Assuming Ride.fromJson exists to parse the ride data
        return rideData.map((data) => Ride.fromJson(data)).toList();
      } else {
        // Handle cases where success might be false or data is empty/null
        print('No available rides found or server indicated failure.');
        return []; // Return empty list
      }
    } else {
      print(
          'Failed to load available rides: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load available rides: ${response.body}');
    }
  }

  // Accept a specific ride
  Future<bool> acceptRide(String rideId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final baseUrl = _getBaseUrl(); // Get base URL from .env

    final response = await http.post(
      Uri.parse('$baseUrl/api/captains/accept-ride'), // Use variable
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'rideId': rideId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['success'] ??
          false; // Return true if success field is true
    } else {
      print('Failed to accept ride: ${response.statusCode} ${response.body}');
      // Consider throwing a more specific error based on response body
      throw Exception('Failed to accept ride: ${response.body}');
    }
  }

  Future<bool> toggleAvailability(bool isAvailable) async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/captains/toggle-availability');
    final headers = await _getHeaders();
    final body = jsonEncode({'isAvailable': isAvailable});

    print("Sending toggleAvailability request:"); // <-- Log request start
    print("  URL: $url");
    print("  Headers: $headers"); // Be careful logging tokens in production
    print("  Body: $body");

    try {
      final response = await http.post(url, headers: headers, body: body);

      print("ToggleAvailability Response:"); // <-- Log response details
      print("  Status Code: ${response.statusCode}");
      print("  Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        bool backendAvailability =
            responseBody['data']?['isAvailable'] ?? false;
        print(
            "  Parsed backend availability: $backendAvailability"); // <-- Log parsed value
        return backendAvailability;
      } else {
        print('Failed to toggle availability: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Optionally parse error message from response.body
        return !isAvailable; // Return the original state on failure
      }
    } catch (e) {
      print('Error toggling availability: $e');
      return !isAvailable; // Return the original state on exception
    }
  }

  Future<bool> declineRide(String rideId, {String? reason}) async {
    final baseUrl = _getBaseUrl(); // Get base URL from .env
    final url = Uri.parse('$baseUrl/api/captains/decline-ride/$rideId');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'reason': reason ?? 'Declined by captain',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Ride $rideId declined successfully: ${responseBody['message']}');
        return responseBody['success'] ??
            true; // Return true if success field is true
      } else {
        print(
            'Failed to decline ride: ${response.statusCode} ${response.body}');
        return false; // Return false on failure
      }
    } catch (e) {
      print('Error declining ride: $e');
      return false; // Return false on exception
    }
  }
  // Import location package with an alias

  // Update captain's location
  Future<bool> updateCaptainLocation(loc.LocationData locationData) async {
    final baseUrl = _getBaseUrl(); // Get base URL from .env
    final url =
        Uri.parse('$baseUrl/api/captains/update-location'); // Correct endpoint
    final headers = await _getHeaders();

    // Ensure latitude and longitude are not null
    if (locationData.latitude == null || locationData.longitude == null) {
      print('Error: Cannot update location with null coordinates.');
      return false;
    }

    final body = jsonEncode({
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
      // Include optional fields if available and needed by backend
      if (locationData.heading != null) 'heading': locationData.heading,
      if (locationData.speed != null) 'speed': locationData.speed,
      // timestamp: DateTime.now().toIso8601String() // Optional: Send timestamp
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully updated location
        // print('Location updated successfully via HTTP.'); // Can be noisy
        return true;
      } else {
        print('Failed to update location: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending location update: $e');
      return false;
    }
  }
}
