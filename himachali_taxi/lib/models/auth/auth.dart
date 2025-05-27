import 'dart:convert';
import 'dart:io' show File, Platform; // Import Platform
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:himachali_taxi/utils/sf_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p; // Import the path package

class AuthService {
  // Removed hardcoded host and base URL
  // static final String _host = '192.168.177.195';
  // static final String _baseUrl = 'http://$_host:3000/api/auth';

  // Helper to get Base URL from .env
  String _getBaseUrl() {
    final baseUrl = dotenv.env['BACKEND_URL'];
    ;
    print("AuthService: Using BASE_URL: $baseUrl"); // <-- Add this line
    if (baseUrl == null || baseUrl.isEmpty) {
      print("ERROR: BASE_URL not found in .env file.");
      throw Exception("BASE_URL not configured in .env file.");
    }
    return baseUrl;
  }

  // Helper to get Auth API endpoint
  String _getAuthApiEndpoint() {
    return '${_getBaseUrl()}/api/auth';
  }

  Future<bool> isAuthenticated() async {
    final token = await SfManager.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await SfManager.getToken();
  }

  Future<String?> getUserId() async {
    return await SfManager.getUserId();
  }

  Future<String?> getUserRole() async {
    final role = await SfManager.getUserRole();
    return role ?? 'user';
  }

  Future<void> saveAuthData(String token, String userId, String role) async {
    await SfManager.setToken(token);
    await SfManager.setUserId(userId);
    await SfManager.setUserRole(role);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final authApiEndpoint = _getAuthApiEndpoint();
      print('Making login request to $authApiEndpoint/$role/login');
      final response = await http.post(
        Uri.parse('$authApiEndpoint/$role/login'), // Use helper method
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Login failed');
      }
      return data;
    } catch (e) {
      print('Login error: $e');
      // Check if the error is due to missing BASE_URL
      if (e.toString().contains("BASE_URL not configured")) {
        throw e; // Re-throw the specific configuration error
      }
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await SfManager.clearAll();
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  Future<Map<String, String?>> getAuthData() async {
    return {
      'token': await SfManager.getToken(),
      'userId': await SfManager.getUserId(),
    };
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final authApiEndpoint = _getAuthApiEndpoint();
      final response = await http.post(
        Uri.parse('$authApiEndpoint/verify-otp'), // Use helper method
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'role': role, // Add role to the request
        }),
      );

      print('OTP Verification Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('OTP Verification Error: $e');
      if (e.toString().contains("BASE_URL not configured")) {
        throw e;
      }
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> resendOTP({required String email}) async {
    try {
      // TODO: Implement API call to resend OTP using _getAuthApiEndpoint()
      await Future.delayed(const Duration(seconds: 1)); // Simulated API call
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$_getBaseUrl()/api/profile/upload-image'), // Use your existing image upload endpoint
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage', // This 'field' name must match what your backend multer setup expects
          imageFile.path,
          contentType:
              MediaType('image', p.extension(imageFile.path).substring(1)),
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        // Assuming your upload endpoint returns { "status": "success", "imageUrl": "..." }
        // or { "success": true, "data": { "imageUrl": "..." } }
        if (decodedResponse['status'] == 'success' &&
            decodedResponse['imageUrl'] != null) {
          return decodedResponse['imageUrl'];
        } else if (decodedResponse['success'] == true &&
            decodedResponse['data']?['imageUrl'] != null) {
          return decodedResponse['data']['imageUrl'];
        }
        print(
            'Image upload response format not recognized or imageUrl missing.');
        return null;
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        print('Image upload error response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final authApiEndpoint = _getAuthApiEndpoint();
      print('Attempting signup...');
      final String endpoint = userData['role'] == 'captain'
          ? '$authApiEndpoint/captain/signup' // Use helper method
          : '$authApiEndpoint/user/signup'; // Use helper method

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...userData,
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('Signup error details: $e');
      if (e.toString().contains("BASE_URL not configured")) {
        throw e;
      }
      if (e.toString().contains('<!DOCTYPE html>')) {
        throw Exception('Server connection error. Please try again later.');
      }
      throw Exception('Failed to sign up: $e');
    }
  }
}
