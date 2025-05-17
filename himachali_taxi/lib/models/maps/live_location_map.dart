import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LiveLocationMap extends StatefulWidget {
  final String userId;
  final String role;
  final String? rideId;

  const LiveLocationMap(
      {super.key,
      required this.userId,
      required this.role,
      required this.rideId});

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  static final CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(31.7754, 76.9861), // Default to Himachal Pradesh
    zoom: 15,
  );

  final Completer<GoogleMapController> _controller = Completer();
  late CameraPosition _initialPosition = _defaultPosition;

  @override
  void initState() {
    super.initState();
    _loadInitialPosition();
  }

  Future<void> _loadInitialPosition() async {
    try {
      final location = await Location().getLocation();
      if (location.latitude != null && location.longitude != null) {
        _initialPosition = CameraPosition(
          target: LatLng(location.latitude!, location.longitude!),
          zoom: 15,
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }
}
