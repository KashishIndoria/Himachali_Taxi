import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himachali_taxi/models/booking_model.dart';
import 'package:himachali_taxi/services/socket_service.dart';
import 'package:himachali_taxi/utils/sf_manager.dart';

class BookingProvider extends ChangeNotifier {
  Booking? _currentBooking;
  List<Booking> _bookingHistory = [];
  bool _isLoading = false;
  String? _error;

  Booking? get currentBooking => _currentBooking;
  List<Booking> get bookingHistory => _bookingHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final SocketService _socketService = SocketService();

  BookingProvider() {
    _initializeSocketListeners();
  }

  void _initializeSocketListeners() {
    _socketService.rideStatusUpdates.listen((data) {
      if (data is Map<String, dynamic>) {
        _handleRideStatusUpdate(data);
      }
    });

    _socketService.newRideRequests.listen((data) {
      if (data is Map<String, dynamic>) {
        _handleNewRideRequest(data);
      }
    });
  }

  void _handleRideStatusUpdate(Map<String, dynamic> data) {
    if (_currentBooking != null && data['bookingId'] == _currentBooking!.id) {
      _currentBooking = _currentBooking!.copyWith(
        status: BookingStatus.values.firstWhere(
          (e) => e.toString() == 'BookingStatus.${data['status']}',
        ),
        captainId: data['captainId'],
        actualFare: data['actualFare']?.toDouble(),
      );
      notifyListeners();
    }
  }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    // Handle new ride request notification
    // This could be used for captain's view
  }

  Future<void> createBooking({
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required String pickupAddress,
    required String dropoffAddress,
    required double estimatedFare,
    String? paymentMethod,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = await SfManager.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final bookingData = {
        'userId': userId,
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
        'estimatedFare': estimatedFare,
        'paymentMethod': paymentMethod,
      };

      _socketService.requestRide(bookingData);

      // The actual booking object will be created when the server responds
      // through the socket connection
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String reason) async {
    if (_currentBooking == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = await SfManager.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _socketService.cancelRideUser(
        userId,
        _currentBooking!.id,
        reason,
      );

      _currentBooking = _currentBooking!.copyWith(
        status: BookingStatus.cancelled,
        cancellationReason: reason,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingHistory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Implement API call to fetch booking history
      // For now, we'll just update the UI
      _bookingHistory = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
