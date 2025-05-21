import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/video_call.dart';
import 'package:himachali_taxi/services/video_call_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class VideoCallProvider extends ChangeNotifier {
  VideoCallService? _videoCallService;
  VideoCall? _currentCall;
  bool _isInitialized = false;
  bool _isCallActive = false;
  String? _error;

  VideoCallService? get videoCallService => _videoCallService;
  VideoCall? get currentCall => _currentCall;
  bool get isInitialized => _isInitialized;
  bool get isCallActive => _isCallActive;
  String? get error => _error;

  Future<void> initialize(IO.Socket socket) async {
    try {
      _videoCallService = VideoCallService(socket);
      await _videoCallService?.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize video call service: $e';
      notifyListeners();
    }
  }

  Future<void> startCall(String targetUserId, String rideId) async {
    try {
      if (_videoCallService == null) {
        throw Exception('Video call service not initialized');
      }

      _isCallActive = true;
      notifyListeners();

      await _videoCallService?.startCall(targetUserId, rideId);
    } catch (e) {
      _error = 'Failed to start call: $e';
      _isCallActive = false;
      notifyListeners();
    }
  }

  Future<void> acceptCall(String callerId, dynamic offer) async {
    try {
      if (_videoCallService == null) {
        throw Exception('Video call service not initialized');
      }

      _isCallActive = true;
      notifyListeners();

      await _videoCallService?.acceptCall(callerId, offer);
    } catch (e) {
      _error = 'Failed to accept call: $e';
      _isCallActive = false;
      notifyListeners();
    }
  }

  void rejectCall(String callerId) {
    _videoCallService?.rejectCall(callerId);
    _isCallActive = false;
    notifyListeners();
  }

  void endCall(String targetUserId) {
    _videoCallService?.endCall(targetUserId);
    _isCallActive = false;
    notifyListeners();
  }

  void setCurrentCall(VideoCall call) {
    _currentCall = call;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoCallService?.dispose();
    super.dispose();
  }
}
