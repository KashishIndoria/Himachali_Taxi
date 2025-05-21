import 'package:flutter/material.dart';

class VideoCall {
  final String id;
  final String initiatorId;
  final String recipientId;
  final String rideId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final double? duration;

  VideoCall({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.rideId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  factory VideoCall.fromJson(Map<String, dynamic> json) {
    return VideoCall(
      id: json['_id'],
      initiatorId: json['initiator'],
      recipientId: json['recipient'],
      rideId: json['ride'],
      status: json['status'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'initiator': initiatorId,
      'recipient': recipientId,
      'ride': rideId,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
    };
  }
}
