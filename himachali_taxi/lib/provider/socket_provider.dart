// himachali_taxi/lib/providers/socket_provider.dart
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'dart:async';

class SocketProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  StreamSubscription? _connectionStatusSubscription;
  bool _isConnected = false;
  String? _socketId;

  SocketService get socketService => _socketService;
  bool get isConnected => _isConnected;
  String? get socketId => _socketId;

  SocketProvider() {
    // Listen to connection status changes from the service
    _connectionStatusSubscription =
        _socketService.connectionStatus.listen((statusData) {
      if (statusData is Map && statusData['status'] == 'connected') {
        _isConnected = true;
        _socketId = statusData['socketId'];
        print('SocketProvider: Connected (ID: $_socketId)');
      } else {
        _isConnected = false;
        _socketId = null;
        print('SocketProvider: Disconnected or Error');
      }
      notifyListeners(); // Notify listeners about connection status change
    });
  }

  // Call this method after successful login
  Future<void> connect(String token, String userId, String userType) async {
    print('SocketProvider: Attempting to connect...');
    try {
      await _socketService.connect(token, userId, userType);
      print('SocketProvider: Connection successful');
    } catch (e) {
      print('SocketProvider: Connection failed - $e');
      _isConnected = false;
      _socketId = null;
      notifyListeners();
    }
  }

  // Call this method on logout
  void disconnect() {
    print('SocketProvider: Disconnecting...');
    _socketService.disconnect();
    _isConnected = false;
    _socketId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('SocketProvider: Disposing...');
    _connectionStatusSubscription?.cancel(); // Cancel the subscription
    _socketService.dispose(); // Dispose the service itself
    super.dispose();
  }
}
