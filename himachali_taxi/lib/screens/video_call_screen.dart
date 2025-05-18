import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final VideoCallService videoCallService;
  final String remoteUserId;
  final String remoteUserName;
  final bool isIncoming;

  const VideoCallScreen({
    Key? key,
    required this.videoCallService,
    required this.remoteUserId,
    required this.remoteUserName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    if (!widget.isIncoming) {
      await widget.videoCallService.startCall(widget.remoteUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Remote Video
              Positioned.fill(
                child: RTCVideoView(
                  widget.videoCallService.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),

              // Local Video (Picture-in-Picture)
              if (!_isMinimized)
                Positioned(
                  right: 16,
                  top: 16,
                  width: 100,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        widget.videoCallService.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // Call Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                        onPressed: _toggleMic,
                        backgroundColor:
                            _isMicMuted ? Colors.red : Colors.white,
                        iconColor: _isMicMuted ? Colors.white : Colors.black,
                      ),
                      _buildControlButton(
                        icon:
                            _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        onPressed: _toggleCamera,
                        backgroundColor:
                            _isCameraOff ? Colors.red : Colors.white,
                        iconColor: _isCameraOff ? Colors.white : Colors.black,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        iconColor: Colors.white,
                        size: 70,
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        onPressed: _toggleSpeaker,
                        backgroundColor:
                            _isSpeakerOn ? Colors.white : Colors.grey,
                        iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                      ),
                      _buildControlButton(
                        icon: _isMinimized
                            ? Icons.fullscreen
                            : Icons.picture_in_picture,
                        onPressed: _toggleMinimize,
                        backgroundColor: Colors.white,
                        iconColor: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              // Call Status Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.remoteUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.videoCallService.isCallActive
                            ? 'Connected'
                            : 'Connecting...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: iconColor,
        iconSize: size * 0.5,
      ),
    );
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
      widget.videoCallService.localStream?.getAudioTracks().forEach((track) {
        track.enabled = !_isMicMuted;
      });
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
      widget.videoCallService.localStream?.getVideoTracks().forEach((track) {
        track.enabled = !_isCameraOff;
      });
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      // Implement speaker toggle logic
    });
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  void _endCall() {
    widget.videoCallService.endCall(widget.remoteUserId);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
