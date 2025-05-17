import 'dart:convert';
import 'dart:io' show Platform; // Import Platform
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../utils/sf_manager.dart';
import '../captain_ride_request.dart';

class RideRequestHandler {
  // Socket instance for real-time updates
  final IO.Socket socket;
  final String captainId;
  final String? token;
  final Function(CaptainRideRequest) onNewRequest;
  final Function(String) onRequestAccepted;
  final Function(String) onRequestCancelled;
  final Function(String) onRideCompleted;
  final Function(String) onError;
  final String _host =
      '192.168.177.195'; // Use the computer's local network IP directly

  RideRequestHandler({
    required this.socket,
    required this.captainId,
    required this.token,
    required this.onNewRequest,
    required this.onRequestAccepted,
    required this.onRequestCancelled,
    required this.onRideCompleted,
    required this.onError,
  }) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen for ride requests
    socket.on('newRideRequest', (data) {
      try {
        print('New ride request received: $data');
        final requestMap = Map<String, dynamic>.from(data);
        final request = CaptainRideRequest.fromJson(requestMap);
        onNewRequest(request);
      } catch (e) {
        onError('Error processing ride request: $e');
      }
    });

    // Listen for ride acceptance confirmation
    socket.on('rideAccepted', (data) {
      try {
        final requestId = data['requestId'];
        print('Ride accepted: $requestId');
        onRequestAccepted(requestId);
      } catch (e) {
        onError('Error processing acceptance: $e');
      }
    });

    // Listen for ride cancellations
    socket.on('rideCancelled', (data) {
      try {
        final requestId = data['requestId'];
        print('Ride cancelled: $requestId');
        onRequestCancelled(requestId);
      } catch (e) {
        onError('Error processing cancellation: $e');
      }
    });

    // Listen for ride completion
    socket.on('rideCompleted', (data) {
      try {
        final requestId = data['requestId'];
        print('Ride completed: $requestId');
        onRideCompleted(requestId);
      } catch (e) {
        onError('Error processing completion: $e');
      }
    });
  }

  // Accept a ride request
  Future<bool> acceptRideRequest(CaptainRideRequest request) async {
    try {
      // Emit event via socket for immediate notification
      socket.emit('acceptRide', {
        'captainId': captainId,
        'requestId': request.id,
      });

      // Also send HTTP request for reliability
      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/accept-ride'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'requestId': request.id,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        onError('Failed to accept ride: ${response.body}');
        return false;
      }
    } catch (e) {
      onError('Error accepting ride: $e');
      return false;
    }
  }

  // Decline a ride request
  Future<bool> declineRideRequest(CaptainRideRequest request) async {
    try {
      socket.emit('declineRide', {
        'captainId': captainId,
        'requestId': request.id,
      });

      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/decline-ride'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'requestId': request.id,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        onError('Failed to decline ride: ${response.body}');
        return false;
      }
    } catch (e) {
      onError('Error declining ride: $e');
      return false;
    }
  }

  // Complete a ride
  Future<bool> completeRide(CaptainRideRequest request) async {
    try {
      socket.emit('completeRide', {
        'captainId': captainId,
        'requestId': request.id,
      });

      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/complete-ride'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'requestId': request.id,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        onError('Failed to complete ride: ${response.body}');
        return false;
      }
    } catch (e) {
      onError('Error completing ride: $e');
      return false;
    }
  }

  // Cancel a ride that was previously accepted
  Future<bool> cancelAcceptedRide(
      CaptainRideRequest request, String reason) async {
    try {
      socket.emit('cancelRide', {
        'captainId': captainId,
        'requestId': request.id,
        'reason': reason,
      });

      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/cancel-ride'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'requestId': request.id,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        onError('Failed to cancel ride: ${response.body}');
        return false;
      }
    } catch (e) {
      onError('Error cancelling ride: $e');
      return false;
    }
  }

  // For backward compatibility with code that uses requestId directly
  Future<bool> acceptRideRequestById(String requestId) async {
    try {
      socket.emit('acceptRide', {
        'captainId': captainId,
        'requestId': requestId,
      });

      final response = await http.post(
        Uri.parse(
            'http://$_host:3000/api/captain/accept-ride'), // Use host variable
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        onError('Failed to accept ride: ${response.body}');
        return false;
      }
    } catch (e) {
      onError('Error accepting ride: $e');
      return false;
    }
  }

  void dispose() {
    // Remove all event listeners to prevent memory leaks
    socket.off('newRideRequest');
    socket.off('rideAccepted');
    socket.off('rideCancelled');
    socket.off('rideCompleted');
  }
}
