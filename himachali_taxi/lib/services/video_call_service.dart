import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class VideoCallService {
  final IO.Socket socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool isCallActive = false;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  VideoCallService(this.socket) {
    _initializeListeners();
  }

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _initializeListeners() {
    socket.on('incoming-call', (data) async {
      if (!isCallActive) {
        isCallActive = true;
        await _handleIncomingCall(data);
      }
    });

    socket.on('call-accepted', (data) async {
      await _handleCallAccepted(data);
    });

    socket.on('call-rejected', (data) {
      _handleCallRejected(data);
    });

    socket.on('call-ended', (data) {
      _handleCallEnded();
    });

    socket.on('ice-candidate', (data) async {
      await _handleIceCandidate(data);
    });
  }

  Future<void> startCall(String targetUserId) async {
    try {
      await _createPeerConnection();
      await _getUserMedia();

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      socket.emit('call-user', {
        'targetUserId': targetUserId,
        'offer': offer.toMap(),
      });
    } catch (e) {
      print('Error starting call: $e');
      _handleCallEnded();
    }
  }

  Future<void> acceptCall(String callerId, dynamic offer) async {
    try {
      await _createPeerConnection();
      await _getUserMedia();

      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          offer['sdp'],
          offer['type'],
        ),
      );

      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      socket.emit('call-accepted', {
        'targetUserId': callerId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      print('Error accepting call: $e');
      _handleCallEnded();
    }
  }

  void rejectCall(String callerId) {
    socket.emit('call-rejected', {
      'targetUserId': callerId,
    });
    _handleCallEnded();
  }

  void endCall(String targetUserId) {
    socket.emit('end-call', {
      'targetUserId': targetUserId,
    });
    _handleCallEnded();
  }

  Future<void> _createPeerConnection() async {
    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      socket.emit('ice-candidate', {
        'candidate': candidate.toMap(),
      });
    };

    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        remoteRenderer.srcObject = remoteStream;
      }
    };
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;

      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });
    } catch (e) {
      print('Error getting user media: $e');
      throw e;
    }
  }

  Future<void> _handleIncomingCall(dynamic data) async {
    // Handle incoming call offer
    if (data['offer'] != null) {
      await acceptCall(data['from'], data['offer']);
    }
  }

  Future<void> _handleCallAccepted(dynamic data) async {
    if (data['answer'] != null) {
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        ),
      );
    }
  }

  void _handleCallRejected(dynamic data) {
    _handleCallEnded();
  }

  void _handleCallEnded() {
    isCallActive = false;
    localStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.getTracks().forEach((track) => track.stop());
    peerConnection?.close();
    localStream = null;
    remoteStream = null;
    peerConnection = null;
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    if (data['candidate'] != null) {
      await peerConnection?.addCandidate(
        RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        ),
      );
    }
  }

  void dispose() {
    _handleCallEnded();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
