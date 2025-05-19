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
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      // Fallback or error handling
      print("ERROR: BACKEND_URL not found in .env file.");
      // You might want to throw an exception or return a default URL
      // For now, let's throw an exception as it's critical
      throw Exception("BACKEND_URL not configured in .env file.");
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

  // Get captain profile
  Future<Map<String, dynamic>> getCaptainProfile(String captainId) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/captains/profile/$captainId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Failed to fetch captain profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching captain profile: $e');
    }
  }

  // Update captain profile
  Future<Map<String, dynamic>> updateCaptainProfile(
      Map<String, dynamic> profileData) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/captains/profile'),
        headers: headers,
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Update profile image
  Future<String> updateProfileImage(String imageUrl) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/captains/update-profile-image'),
        headers: headers,
        body: jsonEncode({'profileImageUrl': imageUrl}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data']['profileImage'];
      } else {
        throw Exception('Failed to update profile image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile image: $e');
    }
  }

  // Get captain status
  Future<Map<String, dynamic>> getCaptainStatus() async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/captains/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Failed to fetch captain status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching captain status: $e');
    }
  }

  // Get available rides near the captain
  Future<List<Ride>> getAvailableRides() async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/captains/available-rides'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return (responseBody['data'] as List)
              .map((data) => Ride.fromJson(data))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch available rides: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching available rides: $e');
    }
  }

  // Accept a specific ride
  Future<bool> acceptRide(String rideId) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/accept-ride'),
        headers: headers,
        body: jsonEncode({'rideId': rideId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to accept ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error accepting ride: $e');
    }
  }

  // Toggle availability
  Future<bool> toggleAvailability(bool isAvailable) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/toggle-availability'),
        headers: headers,
        body: jsonEncode({'isAvailable': isAvailable}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data']['isAvailable'];
      } else {
        throw Exception('Failed to toggle availability: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error toggling availability: $e');
    }
  }

  // Update captain's location
  Future<bool> updateLocation(loc.LocationData locationData) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    if (locationData.latitude == null || locationData.longitude == null) {
      throw Exception('Invalid location data');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/update-location'),
        headers: headers,
        body: jsonEncode({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          if (locationData.heading != null) 'heading': locationData.heading,
          if (locationData.speed != null) 'speed': locationData.speed,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  // Get ride history
  Future<List<Map<String, dynamic>>> getRideHistory(
      {int page = 1, int limit = 10}) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/captains/rides?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['data']['rides']);
      } else {
        throw Exception('Failed to fetch ride history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching ride history: $e');
    }
  }

  // Get earnings
  Future<Map<String, dynamic>> getEarnings({String period = 'all'}) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/captains/earnings?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Failed to fetch earnings: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching earnings: $e');
    }
  }

  // Decline ride
  Future<bool> declineRide(String rideId, {String? reason}) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/decline-ride/$rideId'),
        headers: headers,
        body: jsonEncode({'reason': reason ?? 'Declined by captain'}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to decline ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error declining ride: $e');
    }
  }

  // Complete ride
  Future<bool> completeRide(String rideId,
      {required double finalFare, double? distance, double? duration}) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/complete-ride'),
        headers: headers,
        body: jsonEncode({
          'rideId': rideId,
          'finalFare': finalFare,
          if (distance != null) 'distance': distance,
          if (duration != null) 'duration': duration,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to complete ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing ride: $e');
    }
  }

  // Cancel ride
  Future<bool> cancelRide(String rideId, String reason) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/cancel-ride'),
        headers: headers,
        body: jsonEncode({
          'rideId': rideId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to cancel ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error cancelling ride: $e');
    }
  }

  // Mark as arrived
  Future<bool> markAsArrived(String rideId) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/arrive'),
        headers: headers,
        body: jsonEncode({'rideId': rideId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to mark as arrived: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking as arrived: $e');
    }
  }

  // Start ride
  Future<bool> startRide(String rideId) async {
    final baseUrl = _getBaseUrl();
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/captains/start-ride'),
        headers: headers,
        body: jsonEncode({'rideId': rideId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['success'] ?? false;
      } else {
        throw Exception('Failed to start ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting ride: $e');
    }
  }
}
