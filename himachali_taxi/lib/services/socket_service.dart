// himachali_taxi/lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // To load backend URL
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  final String _backendUrl = dotenv.env['BACKEND_URL'] ??
      'http://localhost:3000'; // Replace with your actual backend URL or load from .env

  // Stream controllers to broadcast received events
  final StreamController<dynamic> _connectionStatusController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _errorController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _rideStatusController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _newRideRequestController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _rideAcceptedController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _rideCancelledController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _rideCompletedController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _captainLocationUpdateController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _captainAvailabilityChangedController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _captainOfflineController =
      StreamController<dynamic>.broadcast();
  // Add new stream controllers if needed for new events like driverArrived, rideStarted, rideTaken
  // Example:
  // final StreamController<dynamic> _driverArrivedController = StreamController<dynamic>.broadcast();
  // final StreamController<dynamic> _rideStartedController = StreamController<dynamic>.broadcast();
  // final StreamController<dynamic> _rideTakenController = StreamController<dynamic>.broadcast();

  // Streams for widgets to listen to
  Stream<dynamic> get connectionStatus => _connectionStatusController.stream;
  Stream<dynamic> get errorEvents => _errorController.stream;
  Stream<dynamic> get rideStatusUpdates => _rideStatusController.stream;
  Stream<dynamic> get newRideRequests => _newRideRequestController.stream;
  Stream<dynamic> get rideAcceptedUpdates => _rideAcceptedController.stream;
  Stream<dynamic> get rideCancelledUpdates => _rideCancelledController.stream;
  Stream<dynamic> get rideCompletedUpdates => _rideCompletedController.stream;
  Stream<dynamic> get captainLocationUpdates =>
      _captainLocationUpdateController.stream;
  Stream<dynamic> get captainAvailabilityChanges =>
      _captainAvailabilityChangedController.stream;
  Stream<dynamic> get captainOfflineUpdates => _captainOfflineController.stream;
  // Add getters for new streams if you added controllers
  // Example:
  // Stream<dynamic> get driverArrivedUpdates => _driverArrivedController.stream;
  // Stream<dynamic> get rideStartedUpdates => _rideStartedController.stream;
  // Stream<dynamic> get rideTakenUpdates => _rideTakenController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  // Modified connectAndListen
  void connectAndListen(String? token, String? userId, String? userType) {
    if (_socket != null && _socket!.connected) {
      print('Socket already connected.');
      // No need to re-authenticate manually here
      return;
    }
    if (token == null) {
      print('Socket connection aborted: No authentication token provided.');
      _connectionStatusController
          .add({'status': 'error', 'data': 'Authentication token missing'});
      return;
    }

    print('Connecting to socket server: $_backendUrl');
    _socket = IO.io(_backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true, // Connect automatically
      // Send token for authentication middleware
      'auth': {'token': token},
    });

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
      _connectionStatusController
          .add({'status': 'connected', 'socketId': _socket!.id});
      // Authentication is handled by middleware, no need to emit 'userConnected' or 'driverConnected'
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _connectionStatusController.add({'status': 'disconnected'});
    });

    _socket!.onConnectError((data) {
      print('Socket connection error: $data');
      _connectionStatusController.add({'status': 'error', 'data': data});
      _errorController.add({'event': 'connect_error', 'data': data});
    });

    _socket!.onError((data) {
      print('Socket error: $data');
      _errorController.add({'event': 'general_error', 'data': data});
    });

    // --- Listen for Server Events ---
    // ... existing listeners for rideStatus, newRideRequest, etc. ...
    _socket!.on('rideStatus', (data) {
      print('Received rideStatus: $data');
      _rideStatusController.add(data);
    });

    _socket!.on('newRideRequest', (data) {
      print('Received newRideRequest: $data');
      _newRideRequestController.add(data);
    });

    _socket!.on('rideAccepted', (data) {
      print('Received rideAccepted: $data');
      _rideAcceptedController.add(data);
    });

    _socket!.on('driverArrived', (data) {
      // Listen for driverArrived
      print('Received driverArrived: $data');
      // Add a stream controller if needed, or handle directly
      // Example: _driverArrivedController.add(data);
      _rideStatusController
          .add({'event': 'driverArrived', 'data': data}); // Or reuse rideStatus
    });
    _socket!.on('rideTaken', (data) {
      print('Received rideTaken: $data');
      if (data is Map<String, dynamic>) {
        _newRideRequestController.add({
          'event': 'rideTaken', // Add event identifier
          'data': data
        });
      } else {
        print('Received rideTaken event with unexpected data type: $data');
        // Optionally add to error stream or handle differently
        _errorController.add({'event': 'rideTaken_invalid_data', 'data': data});
      }
    });

    _socket!.on('rideStarted', (data) {
      // Listen for rideStarted
      print('Received rideStarted: $data');
      // Add a stream controller if needed, or handle directly
      // Example: _rideStartedController.add(data);
      _rideStatusController
          .add({'event': 'rideStarted', 'data': data}); // Or reuse rideStatus
    });

    _socket!.on('rideCancelled', (data) {
      print('Received rideCancelled: $data');
      _rideCancelledController.add(data);
    });

    _socket!.on('rideCompleted', (data) {
      print('Received rideCompleted: $data');
      _rideCompletedController.add(data);
    });

    _socket!.on('rideTaken', (data) {
      // Listen for rideTaken
      print('Received rideTaken: $data');
      // Handle event, e.g., remove ride from available list
      // Add a stream controller if needed
      // Example: _rideTakenController.add(data);
      _newRideRequestController.add(
          {'event': 'rideTaken', 'data': data}); // Or reuse newRideRequests
    });

    _socket!.on('captainLocationUpdate', (data) {
      // Avoid excessive printing for location updates
      // print('Received captainLocationUpdate: $data');
      _captainLocationUpdateController.add(data);
    });

    _socket!.on('captainAvailabilityChanged', (data) {
      print('Received captainAvailabilityChanged: $data');
      _captainAvailabilityChangedController.add(data);
    });

    _socket!.on('captainOffline', (data) {
      print('Received captainOffline: $data');
      _captainOfflineController.add(data);
    });

    // Listen for generic errors from backend
    _socket!.on('error', (data) {
      print('Received error event from server: $data');
      _errorController.add({'event': 'server_error', 'data': data});
    });
  }

  // --- Emit Client Events ---

  // REMOVE OLD AUTHENTICATION METHODS
  // void authenticateUser(String userId, String token) { ... }
  // void authenticateCaptain(String driverId, String token) { ... }

  // Keep methods that emit application events if needed, BUT prefer HTTP requests for actions
  // These emit methods might become redundant if actions are moved to HTTP calls

  // Example: updateCaptainAvailability might be replaced by an HTTP call in ApiService
  void updateCaptainAvailability(String captainId, bool isAvailable) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit(
        'updateCaptainAvailability', // This event might not be handled by the cleaned-up socket.js
        {'captainId': captainId, 'isAvailable': isAvailable});
    print("Emitted updateCaptainAvailability (Note: Backend might not listen)");
  }

  // Example: updateCaptainLocation might be replaced by an HTTP call in ApiService
  void updateCaptainLocation(
      String captainId, double latitude, double longitude,
      {double? heading, double? speed}) {
    // This is handled by the HTTP POST /api/captains/location now
    // if (_socket == null || !_socket!.connected) return;
    // _socket!.emit('updateCaptainLocation', { ... });
    print(
        "updateCaptainLocation via socket is deprecated. Use ApiService.updateCaptainLocation.");
  }

  // Example: requestRide should likely be an HTTP POST request via ApiService
  void requestRide(Map<String, dynamic> rideData) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('requestRide',
        rideData); // This event might not be handled by the cleaned-up socket.js
    print("Emitted requestRide (Note: Backend might not listen)");
  }

  // Example: acceptRide should be an HTTP POST request via ApiService
  void acceptRide(String captainId, String rideId) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('acceptRide', {
      'captainId': captainId,
      'requestId': rideId
    }); // This event might not be handled by the cleaned-up socket.js
    print("Emitted acceptRide (Note: Backend might not listen)");
  }

  // Example: cancelRideUser should be an HTTP POST request via ApiService
  void cancelRideUser(String userId, String rideId, String reason) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit(
        'cancelRideUser', // This event might not be handled by the cleaned-up socket.js
        {'userId': userId, 'rideId': rideId, 'reason': reason});
    print("Emitted cancelRideUser (Note: Backend might not listen)");
  }

  // Example: cancelRideCaptain should be an HTTP POST request via ApiService
  void cancelRideCaptain(String captainId, String rideId, String reason) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit(
        'cancelRide', // This event might not be handled by the cleaned-up socket.js
        {'captainId': captainId, 'requestId': rideId, 'reason': reason});
    print("Emitted cancelRideCaptain (Note: Backend might not listen)");
  }

  // Example: completeRide should be an HTTP POST request via ApiService
  void completeRide(String captainId, String rideId) {
    // Consider moving this to an HTTP request via ApiService
    if (_socket == null || !_socket!.connected) return;
    _socket! // This event might not be handled by the cleaned-up socket.js
        .emit('completeRide', {'captainId': captainId, 'requestId': rideId});
    print("Emitted completeRide (Note: Backend might not listen)");
  }

  void disconnect() {
    print('Disconnecting socket...');
    _socket?.disconnect();
    _socket?.dispose(); // Clean up resources
    _socket = null;
  }

  // Dispose stream controllers when service is no longer needed
  void dispose() {
    _connectionStatusController.close();
    _errorController.close();
    _rideStatusController.close();
    _newRideRequestController.close();
    _rideAcceptedController.close();
    _rideCancelledController.close();
    _rideCompletedController.close();
    _captainLocationUpdateController.close();
    _captainAvailabilityChangedController.close();
    _captainOfflineController.close();
    // Close any new stream controllers you added
    // Example:
    // _driverArrivedController.close();
    // _rideStartedController.close();
    // _rideTakenController.close();
    disconnect(); // Ensure socket is disconnected on dispose
  }
}
