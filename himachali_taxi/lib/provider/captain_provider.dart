// himachali_taxi/lib/provider/captain_provider.dart
import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';
import '../services/captain_services.dart';

class CaptainProvider with ChangeNotifier {
  final CaptainService _captainService = CaptainService();

  List<Ride> _availableRides = [];
  bool _isLoading = false;
  bool _mounted = true; // Track if the provider is mounted
  String? _errorMessage;

  List<Ride> get availableRides => _availableRides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch available rides
  Future<void> fetchAvailableRides() async {
    _isLoading = true;
    _errorMessage = null;
    if (_mounted) notifyListeners();

    try {
      _availableRides = await _captainService.getAvailableRides();
    } catch (error) {
      _errorMessage = error.toString();
      print("Error fetching available rides: $_errorMessage");
      _availableRides = []; // Clear rides on error
    } finally {
      _isLoading = false;
      if (_mounted) notifyListeners();
    }
  }

  // Accept a ride
  Future<bool> acceptRide(String rideId) async {
    _isLoading = true; // Indicate loading state for accepting
    _errorMessage = null;
    if (_mounted) notifyListeners();

    bool success = false;
    try {
      success = await _captainService.acceptRide(rideId);
      if (success) {
        // Remove the accepted ride from the local list
        _availableRides.removeWhere((ride) => ride.id == rideId);
      } else {
        _errorMessage = "Failed to accept ride. It might have been taken.";
      }
    } catch (error) {
      _errorMessage = error.toString();
      print("Error accepting ride: $_errorMessage");
      success = false;
    } finally {
      _isLoading = false;
      if (_mounted) notifyListeners();
    }
    return success;
  }

  // Call this when a ride is cancelled via socket or declined locally
  void removeRideById(String rideId) {
    final index = _availableRides.indexWhere((ride) => ride.id == rideId);
    if (index != -1) {
      _availableRides.removeAt(index);
      print("Removed ride $rideId from local list.");
      if (_mounted) notifyListeners();
    } else {
      print("Ride $rideId not found in local list to remove.");
    }
  }

  // Call this when captain goes offline
  void clearRides() {
    if (_availableRides.isNotEmpty) {
      _availableRides.clear();
      print("Cleared local available rides list.");
      if (_mounted) notifyListeners();
    } else {
      print("Local available rides list already empty.");
    }
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted to false when disposing
    super.dispose();
  }
}
