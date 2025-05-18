import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride.dart';
import '../services/service_provider.dart';
import '../widgets/loading_error_state.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({Key? key}) : super(key: key);

  @override
  _RideBookingScreenState createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final _rideService = ServiceProvider().rideService;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  bool _isLoading = false;
  String? _error;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _pickupLocation = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });

      _moveCamera(_pickupLocation!);
      await _getAddressFromLatLng(_pickupLocation!, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location, bool isPickup) async {
    try {
      // Use Google Maps Geocoding API or any other service to get address
      // For now, using coordinates as address
      final address = '${location.latitude}, ${location.longitude}';
      setState(() {
        if (isPickup) {
          _pickupAddress = address;
        } else {
          _dropoffAddress = address;
        }
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _moveCamera(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 15,
        ),
      ),
    );
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        if (_pickupLocation != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        if (_dropoffLocation != null)
          Marker(
            markerId: const MarkerId('dropoff'),
            position: _dropoffLocation!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Dropoff Location'),
          ),
      };
    });
  }

  Future<void> _bookRide() async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both pickup and dropoff locations')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ride = await _rideService.bookRide(
        pickup: _pickupLocation!,
        pickupAddress: _pickupAddress,
        dropoff: _dropoffLocation!,
        dropoffAddress: _dropoffAddress,
      );

      // Navigate to ride tracking screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/ride-tracking',
            arguments: ride);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: LoadingErrorState(
        isLoading: _isLoading,
        error: _error,
        onRetry: _getCurrentLocation,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(0, 0),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (location) {
                if (_pickupLocation == null) {
                  setState(() {
                    _pickupLocation = location;
                    _updateMarkers();
                  });
                  _getAddressFromLatLng(location, true);
                } else if (_dropoffLocation == null) {
                  setState(() {
                    _dropoffLocation = location;
                    _updateMarkers();
                  });
                  _getAddressFromLatLng(location, false);
                }
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _pickupAddress),
                        decoration: InputDecoration(
                          labelText: 'Pickup Location',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        controller:
                            TextEditingController(text: _dropoffAddress),
                        decoration: const InputDecoration(
                          labelText: 'Dropoff Location',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickupLocation != null &&
                                  _dropoffLocation != null
                              ? _bookRide
                              : null,
                          child: const Text('Book Ride'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
