import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/models/ride_model.dart';
import 'package:himachali_taxi/provider/captain_provider.dart';
import 'package:himachali_taxi/provider/socket_provider.dart';
import 'package:himachali_taxi/services/captain_services.dart';
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as loc;

class CaptainHomeScreen extends StatefulWidget {
  final String userId;
  final String token;

  const CaptainHomeScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _CaptainHomeScreenState createState() => _CaptainHomeScreenState();
}

class _CaptainHomeScreenState extends State<CaptainHomeScreen> {
  GoogleMapController? mapController;
  bool isAvailable = false;
  bool _isLoadingAvailability = false;
  loc.Location _location = loc.Location();
  late SocketProvider _socketProvider;
  StreamSubscription? _rideCancelledSubscription;
  StreamSubscription? _paymentCompletedSubscription;
  StreamSubscription? _newRideRequestSubscription;
  StreamSubscription? _locationSubscription;
  Timer? _locationUpdatedTimer;
  loc.LocationData? _currentLocationData;
  bool _isMapReady = false;
  bool _hasLocationPermission = false;

  Set<Marker> _rideMarkers = {};
  final CaptainService _captainService = CaptainService();

  @override
  void initState() {
    super.initState();
    _socketProvider = Provider.of<SocketProvider>(context, listen: false);
    _initializeLocation();
    _setupSocketListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
      Provider.of<CaptainProvider>(context, listen: false)
          .addListener(_updateRideMarkers);
    });
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    mapController?.dispose();
    _rideCancelledSubscription?.cancel();
    _paymentCompletedSubscription?.cancel();
    _newRideRequestSubscription?.cancel();
    _locationSubscription?.cancel();
    _locationUpdatedTimer?.cancel();
    Provider.of<CaptainProvider>(context, listen: false)
        .removeListener(_updateRideMarkers);
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _showErrorSnackBar('Location services are required for this app');
          return;
        }
      }

      loc.PermissionStatus permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          _showErrorSnackBar('Location permission is required for this app');
          return;
        }
      }

      setState(() {
        _hasLocationPermission = true;
      });

      _startLocationUpdates();
    } catch (e) {
      _showErrorSnackBar('Error initializing location: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    if (!_hasLocationPermission) return;

    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen(
      (loc.LocationData currentLocation) {
        if (!mounted) return;
        setState(() {
          _currentLocationData = currentLocation;
        });

        if (isAvailable) {
          _socketProvider.socketService.updateCaptainLocation(
            widget.userId,
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
            heading: currentLocation.heading,
            speed: currentLocation.speed,
          );
        }
      },
      onError: (e) {
        _showErrorSnackBar('Error updating location: $e');
      },
    );

    _startSendingLocationUpdates();
  }

  void _startSendingLocationUpdates() {
    _locationUpdatedTimer?.cancel();
    _locationUpdatedTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted || !isAvailable) return;

      try {
        final location = await _location.getLocation();
        await _captainService.updateLocation(location);
      } catch (e) {
        _showErrorSnackBar('Error sending location update: $e');
      }
    });
  }

  void _setupSocketListeners() async {
    await _socketProvider.socketService
        .connect(widget.token, widget.userId, 'captain');
    _setupRideListeners();
  }

  void _setupRideListeners() {
    _rideCancelledSubscription?.cancel();
    _rideCancelledSubscription = _socketProvider
        .socketService.rideCancelledUpdates
        .listen(_handleRideCancelled, onError: (e) {
      _showErrorSnackBar('Error in ride cancellation listener: $e');
    });

    _paymentCompletedSubscription?.cancel();
    _paymentCompletedSubscription = _socketProvider
        .socketService.rideCompletedUpdates
        .listen(_handlePaymentCompleted, onError: (e) {
      _showErrorSnackBar('Error in payment completion listener: $e');
    });

    _newRideRequestSubscription?.cancel();
    _newRideRequestSubscription = _socketProvider.socketService.newRideRequests
        .listen(_handleNewRideRequest, onError: (e) {
      _showErrorSnackBar('Error in new ride request listener: $e');
    });
  }

  void _handleRideCancelled(dynamic data) async {
    if (!mounted) return;

    final rideId = data?['rideId'] as String?;
    if (rideId != null) {
      Provider.of<CaptainProvider>(context, listen: false)
          .removeRideById(rideId);
    }

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A ride request was cancelled'),
        backgroundColor: Colors.orange,
      ),
    );

    await _refreshRides();
  }

  void _handlePaymentCompleted(dynamic data) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment received for a ride'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNewRideRequest(dynamic data) async {
    if (!mounted) return;
    await _refreshRides();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    await _refreshRides();
  }

  void _updateRideMarkers() {
    if (!mounted) return;
    final provider = Provider.of<CaptainProvider>(context, listen: false);
    final Set<Marker> markers = {};
    for (var ride in provider.availableRides) {
      if (ride.pickupLat != null && ride.pickupLng != null) {
        markers.add(
          Marker(
              markerId: MarkerId('ride_${ride.id}'),
              position: LatLng(ride.pickupLat!, ride.pickupLng!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Ride Request: ₹${ride.fare.toStringAsFixed(0)}',
                snippet: ride.pickupAddress ?? 'Tap for details',
                onTap: () {
                  _showRideDetailsBottomSheet(ride);
                },
              ),
              onTap: () {
                // Optional: Center map on marker tap or show minimal info
                // mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(ride.pickupLat!, ride.pickupLng!)));
              }),
        );
      } else {
        print(
            "Invalid pickup location for ride ${ride.id} due to missing coordinates.");
      }
    }
    if (mounted) {
      setState(() {
        _rideMarkers = markers;
      });
    }
  }

  void _showRideDetailsBottomSheet(Ride ride) {
    if (!mounted) return;

    final ThemeProvider themeProvider =
        Provider.of<ThemeProvider>(context, listen: false);
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;
    final timeFormat = DateFormat('hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ride Details',
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close))
                ],
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person, size: 20),
                ),
                title: Text(ride.userName ?? 'Passenger',
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: ride.userRating != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(' ${ride.userRating!.toStringAsFixed(1)}'),
                        ],
                      )
                    : null,
                trailing: Text(
                  '₹${ride.fare.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 15, thickness: 1),
              _buildLocationItem(
                icon: Icons.my_location,
                title: 'Pickup',
                address: ride.pickupAddress ?? 'N/A',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _buildLocationItem(
                icon: Icons.location_on,
                title: 'Dropoff',
                address: ride.dropAddress ?? 'N/A',
                color: Colors.red,
              ),
              const SizedBox(height: 8),
              if (ride.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Text(
                    'Requested: ${timeFormat.format(ride.createdAt!.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Divider(height: 20, thickness: 1),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRideRequest(ride.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRideRequest(ride.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryCaptainColor,
                        foregroundColor: themeProvider.isDarkMode
                            ? DarkColors.onPrimaryCaptain
                            : LightColors.onPrimaryCaptain,
                      ),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(address, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _acceptRideRequest(String rideId) async {
    if (!mounted) return;
    final provider = Provider.of<CaptainProvider>(context, listen: false);

    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    final success = await provider.acceptRide(rideId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Ride Accepted!'
            : 'Failed to accept ride: ${provider.errorMessage ?? 'Maybe already taken?'}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) {
    } else {
      if (!mounted) return;
      _refreshRides();
    }
  }

  void _declineRideRequest(String rideId) async {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    try {
      final success = await _captainService.declineRide(rideId);

      if (!mounted) return;

      if (success) {
        if (!mounted) return;
        Provider.of<CaptainProvider>(context, listen: false)
            .removeRideById(rideId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride Declined')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to decline ride'),
              backgroundColor: Colors.red),
        );
        if (!mounted) return;
        _refreshRides();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error declining ride: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refreshRides() async {
    if (!mounted) return;
    final provider = Provider.of<CaptainProvider>(context, listen: false);
    await provider.fetchAvailableRides();
  }

  Future<void> _moveToCurrentLocation() async {
    if (!mounted || !_isMapReady) return;
    try {
      final location = await _location.getLocation();
      if (location.latitude != null && location.longitude != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(location.latitude!, location.longitude!),
            15.0,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error moving to current location: $e');
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      await _captainService.toggleAvailability(value);
      setState(() {
        isAvailable = value;
      });
    } catch (e) {
      _showErrorSnackBar('Error toggling availability: $e');
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final captainProvider = Provider.of<CaptainProvider>(context);

        final onPrimaryCaptainColor = themeProvider.isDarkMode
            ? DarkColors.onPrimaryCaptain
            : LightColors.onPrimaryCaptain;
        final primaryCaptainColor = themeProvider.isDarkMode
            ? DarkColors.primaryCaptain
            : LightColors.primaryCaptain;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  child: Image.asset(
                    "assets/images/taxilogo.png",
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Captain Dashboard",
                  style: TextStyle(color: onPrimaryCaptainColor),
                ),
              ],
            ),
            backgroundColor: primaryCaptainColor,
            actions: [
              if (isAvailable)
                IconButton(
                  icon: Icon(Icons.refresh, color: onPrimaryCaptainColor),
                  onPressed: captainProvider.isLoading ? null : _refreshRides,
                  tooltip: 'Refresh Rides',
                ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Switch(
                    value: isAvailable,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withOpacity(0.5),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    onChanged:
                        _isLoadingAvailability ? null : _toggleAvailability,
                  ),
                  if (_isLoadingAvailability)
                    Positioned(
                      right: 10,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              onPrimaryCaptainColor),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              _buildHomeMapView(themeProvider),
              if (captainProvider.isLoading &&
                  captainProvider.availableRides.isEmpty)
                Center(child: CircularProgressIndicator()),
              if (isAvailable) _buildRideOverlay(captainProvider),
              if (captainProvider.errorMessage != null &&
                  captainProvider.availableRides.isEmpty &&
                  isAvailable)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.black54,
                    child: Text(
                      'Error loading rides: ${captainProvider.errorMessage}',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: CaptainNavBar(
            currentIndex: 0,
            userId: widget.userId,
            token: widget.token,
          ),
        );
      },
    );
  }

  Widget _buildRideOverlay(CaptainProvider captainProvider) {
    if (captainProvider.availableRides.isEmpty && !captainProvider.isLoading) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No available rides at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Available Rides (${captainProvider.availableRides.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: captainProvider.availableRides.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final ride = captainProvider.availableRides[index];
                  return ListTile(
                    leading:
                        const Icon(Icons.pin_drop_outlined, color: Colors.blue),
                    title: Text(ride.pickupAddress ?? 'Pickup Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(ride.dropAddress ?? 'Dropoff Location',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('₹${ride.fare.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () => _showRideDetailsBottomSheet(ride),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeMapView(ThemeProvider themeProvider) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            mapController = controller;
            setState(() {
              _isMapReady = true;
            });
            _moveToCurrentLocation();
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0),
            zoom: 15,
          ),
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: _hasLocationPermission,
          mapToolbarEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
          markers: _rideMarkers,
          padding: EdgeInsets.only(bottom: 50, top: 50),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: themeProvider.isDarkMode
                ? DarkColors.surface
                : LightColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? 'You are online' : 'You are offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? DarkColors.text
                          : LightColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isAvailable
                        ? 'You\'re visible to nearby passengers'
                        : 'Go online to receive ride requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode
                          ? DarkColors.subtext
                          : LightColors.subtext,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingAvailability
                          ? null
                          : () => _toggleAvailability(!isAvailable),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingAvailability
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isAvailable ? 'Go Offline' : 'Go Online',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
