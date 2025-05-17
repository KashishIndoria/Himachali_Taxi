import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _baseUrl =
    '${dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000'}/api';

class ApiService {
  // Helper function to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // Adjust 'authToken' if you store the token under a different key
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      // Adjust 'Bearer' if your backend expects a different auth scheme
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Function to submit a ride rating
  Future<bool> submitRideRating({
    required String rideId,
    required double rating,
    String? comment,
  }) async {
    final url = Uri.parse('$_baseUrl/ratings');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'rideId': rideId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        print('Rating submitted successfully');
        return true;
      } else {
        print('Failed to submit rating: \${response.statusCode}');
        print('Response body: \${response.body}');
        // Consider throwing a specific exception or returning an error message
        return false;
      }
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }

  // Function to get ratings for a specific driver
  Future<Map<String, dynamic>?> getDriverRatings(String driverId) async {
    final url = Uri.parse('$_baseUrl/ratings/driver/$driverId');
    // No token needed usually for fetching driver ratings, but adjust if your backend requires it
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to get driver ratings: \${response.statusCode}');
        print('Response body: \${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching driver ratings: $e');
      return null;
    }
  }

  // Add other API service methods here (e.g., login, signup, fetchUserProfile, etc.)
  // if this service will handle more than just ratings.
}
