// himachali_taxi/lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // To load backend URL
import 'dart:async';
import 'package:himachali_taxi/utils/sf_manager.dart';

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

  // Stream getters
  Stream<Map<String, dynamic>> get rideStatusStream =>
      _rideStatusController.stream.map((data) => data as Map<String, dynamic>);
  Stream<Map<String, dynamic>> get captainLocationStream =>
      _captainLocationUpdateController.stream
          .map((data) => data as Map<String, dynamic>);
  Stream<Map<String, dynamic>> get errorStream =>
      _errorController.stream.map((data) => data as Map<String, dynamic>);

  bool get isConnected => _socket?.connected ?? false;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  // Reconnection configuration
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const int RECONNECT_DELAY = 5000; // 5 seconds
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isManuallyDisconnected = false;

  Future<void> connect(String token, String userId, String userType) async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _isManuallyDisconnected = false;
    _reconnectAttempts = 0;

    try {
      _socket = IO.io(
        _backendUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(MAX_RECONNECT_ATTEMPTS)
            .setReconnectionDelay(RECONNECT_DELAY)
            .build(),
      );

      _setupSocketListeners();
      _setupReconnectionHandlers();

      // Wait for connection
      await _waitForConnection();

      // Join user-specific room
      _socket!.emit('join', userId);

      if (userType == 'captain') {
        _socket!.emit('join', 'captains');
      }
    } catch (e) {
      _errorController.add(
          {'event': 'connection_error', 'message': 'Failed to connect: $e'});
      _attemptReconnect();
    }
  }

  void _setupReconnectionHandlers() {
    _socket!.onConnect((_) {
      _reconnectAttempts = 0;
      _errorController.add(
          {'event': 'connection_status', 'message': 'Connected to server'});
    });

    _socket!.onDisconnect((_) {
      if (!_isManuallyDisconnected) {
        _errorController.add({
          'event': 'connection_status',
          'message': 'Disconnected from server'
        });
        _attemptReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _errorController.add(
          {'event': 'connection_error', 'message': 'Connection error: $error'});
      _attemptReconnect();
    });

    _socket!.onError((error) {
      _errorController
          .add({'event': 'socket_error', 'message': 'Socket error: $error'});
    });
  }

  void _attemptReconnect() {
    if (_isManuallyDisconnected ||
        _reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: RECONNECT_DELAY), () async {
      _reconnectAttempts++;

      if (_reconnectAttempts <= MAX_RECONNECT_ATTEMPTS) {
        _errorController.add({
          'event': 'reconnection_attempt',
          'message':
              'Attempting to reconnect (${_reconnectAttempts}/$MAX_RECONNECT_ATTEMPTS)'
        });

        try {
          final token = await SfManager.getToken();
          final userId = await SfManager.getUserId();
          final userType = await SfManager.getUserRole();

          if (token != null && userId != null && userType != null) {
            await connect(token, userId, userType);
          }
        } catch (e) {
          _errorController.add({
            'event': 'reconnection_error',
            'message': 'Failed to reconnect: $e'
          });
        }
      } else {
        _errorController.add({
          'event': 'reconnection_failed',
          'message': 'Max reconnection attempts reached'
        });
      }
    });
  }

  Future<void> _waitForConnection() async {
    if (_socket == null) return;

    Completer<void> completer = Completer<void>();

    void onConnect(_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void onConnectError(error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    _socket!.onConnect(onConnect);
    _socket!.onConnectError(onConnectError);

    try {
      await completer.future;
    } finally {
      _socket!.off('connect', onConnect);
      _socket!.off('connect_error', onConnectError);
    }
  }

  void disconnect() {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.on('rideStatus', (data) {
      _rideStatusController.add(data);
    });

    _socket!.on('newRideRequest', (data) {
      _newRideRequestController.add(data);
    });

    _socket!.on('rideCancelled', (data) {
      _rideCancelledController.add(data);
    });

    _socket!.on('rideCompleted', (data) {
      _rideCompletedController.add(data);
    });

    _socket!.on('captainLocation', (data) {
      _captainLocationUpdateController.add(data);
    });

    _socket!.on('captainAvailabilityChanged', (data) {
      _captainAvailabilityChangedController.add(data);
    });

    _socket!.on('captainOffline', (data) {
      _captainOfflineController.add(data);
    });

    _socket!.on('error', (data) {
      _errorController.add(data);
    });

    _socket!.on('connection_status', (data) {
      _connectionStatusController.add(data);
    });
  }

  // Add back essential ride-related methods
  void requestRide(Map<String, dynamic> rideData) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('requestRide', rideData);
  }

  void cancelRideUser(String userId, String rideId, String reason) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('cancelRideUser',
        {'userId': userId, 'rideId': rideId, 'reason': reason});
  }

  void updateCaptainLocation(
      String captainId, double latitude, double longitude,
      {double? heading, double? speed}) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('updateLocation', {
      'latitude': latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed
    });
  }

  void updateRideStatus(String rideId, String status,
      {Map<String, dynamic>? location}) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('updateRideStatus', {
      'rideId': rideId,
      'status': status,
      if (location != null) 'location': location
    });
  }

  // Add ride acceptance and decline methods
  Future<bool> acceptRide(String rideId) async {
    if (_socket == null || !_socket!.connected) {
      _errorController.add({'message': 'Socket not connected'});
      return false;
    }

    try {
      _socket!.emit('rideResponse', {'rideId': rideId, 'accepted': true});
      return true;
    } catch (e) {
      _errorController.add({'message': 'Error accepting ride: $e'});
      return false;
    }
  }

  Future<bool> declineRide(String rideId) async {
    if (_socket == null || !_socket!.connected) {
      _errorController.add({'message': 'Socket not connected'});
      return false;
    }

    try {
      _socket!.emit('rideResponse', {
        'rideId': rideId,
        'accepted': false,
        'reason': 'Declined by captain'
      });
      return true;
    } catch (e) {
      _errorController.add({'message': 'Error declining ride: $e'});
      return false;
    }
  }

  void dispose() {
    disconnect();
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
  }
}
