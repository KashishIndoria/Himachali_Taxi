import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/models/ride_model.dart'; // Use the correct Ride model
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
  loc.Location _location = loc.Location(); // Add location instance
  late SocketProvider _socketProvider; // Use SocketProvider
  StreamSubscription? _rideCancelledSubscription; // Add subscription variable
  StreamSubscription? _paymentCompletedSubscription;
  StreamSubscription? _newRideRequestSubscription;

  Set<Marker> _rideMarkers = {};
  final CaptainService _captainService =
      CaptainService(); // Instance of your service
  Timer? _locationUpdatedTimer;
  loc.LocationData? _currentLocationData;

  @override
  void initState() {
    super.initState();
    _socketProvider = Provider.of<SocketProvider>(context, listen: false);
    _startLocationUpdates(); // Start location updates
    _setupSocketListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
      // Listen to provider changes to update markers
      Provider.of<CaptainProvider>(context, listen: false)
          .addListener(_updateRideMarkers);
    });
  }

  Future<void> _fetchInitialData() async {
    // Ensure mounted before proceeding, especially if initState could complete
    // and then this callback runs much later after a dispose.
    if (!mounted) return;
    await _refreshRides();
    // Move map initially after fetching data and ensuring map is ready
    // We call _moveToCurrentLocation in _onMapCreated now.
  }

  // New method to handle map creation
  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    mapController = controller;
    // Optionally move camera to current location once map is ready
    _moveToCurrentLocation();
  }

  // New method to move the map camera
  Future<void> _moveToCurrentLocation() async {
    if (!mounted) return; // Add check at the beginning
    try {
      // Ensure permissions are granted (already done in _startLocationUpdates)
      var currentLocation = await _location.getLocation();
      if (!mounted) return; // Add check after await

      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        if (!mounted) return; // Check before mapController usage
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
            15.0, // Adjust zoom level as needed
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print("Error getting initial location for map centering: $e");
      }
      // Handle cases where location cannot be fetched
    }
  }

  Future<void> _refreshRides() async {
    if (!mounted) return; // Check at the beginning
    final provider = Provider.of<CaptainProvider>(context, listen: false);
    // listen:false makes context usage safer here, but an extra mounted check is harmless.
    if (!mounted) return;
    await provider.fetchAvailableRides();
    // No setState or further context use here, so this should be fine.
  }

  void _updateRideMarkers() {
    if (!mounted) return; // Check before provider access
    final provider = Provider.of<CaptainProvider>(context, listen: false);
    final Set<Marker> markers = {};
    for (var ride in provider.availableRides) {
      if (ride.pickupLat != null && ride.pickupLng != null) {
        markers.add(
          Marker(
              markerId: MarkerId('ride_${ride.id}'),
              position: LatLng(ride.pickupLat!, ride.pickupLng!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen), // Example icon
              infoWindow: InfoWindow(
                title: 'Ride Request: ₹${ride.fare.toStringAsFixed(0)}',
                snippet: ride.pickupAddress ?? 'Tap for details',
                onTap: () {
                  // Show details when marker info window is tapped
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

  void _startLocationUpdates() async {
    // No direct context usage or setState here, but async operations follow.
    // Initial checks for service/permission are fine
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check location permissions
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // Start listening to location changes
    // _location.onLocationChanged.listen((loc.LocationData currentLocation) {
    //   if (!mounted) return; // Good practice if this listener were active
    //   if (isAvailable) {
    //     _socketProvider.socketService.updateCaptainLocation(
    //       widget.userId,
    //       currentLocation.latitude ?? 0.0,
    //       currentLocation.longitude ?? 0.0,
    //       heading: currentLocation.heading,
    //       speed: currentLocation.speed,
    //     );
    //   }
    // });
    print(
        "Location service enabled and permissions granted. HTTP updates will start if captain goes online.");
  }

  void _setupSocketListeners() {
    // Listen for ride cancellations (if needed on captain side)
    _rideCancelledSubscription?.cancel(); // Cancel previous if any
    _rideCancelledSubscription =
        _socketProvider.socketService.rideCancelledUpdates.listen((data) async {
      if (!mounted) return; // Check at the start of the callback

      final rideId = data?['rideId'] as String?;
      if (rideId != null) {
        if (!mounted) return;
        Provider.of<CaptainProvider>(context, listen: false)
            .removeRideById(rideId);
      }

      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A ride request was cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      if (!mounted) return;
      _refreshRides();
    });

    // Listen for payment completion (if needed)
    _paymentCompletedSubscription?.cancel(); // Cancel previous if any
    _paymentCompletedSubscription =
        _socketProvider.socketService.rideCompletedUpdates.listen((data) async {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment received for a ride'),
          backgroundColor: Colors.green,
        ),
      );
    });

    _newRideRequestSubscription?.cancel();
    _newRideRequestSubscription =
        _socketProvider.socketService.newRideRequests.listen((data) {
      if (!mounted) return;

      if (data is Map<String, dynamic>) {
        if (data['event'] == 'rideTaken') {
          final rideData = data['data'] as Map<String, dynamic>?;
          final rideId = rideData?['rideId'] as String?;
          if (rideId != null) {
            if (!mounted) return;
            Provider.of<CaptainProvider>(context, listen: false)
                .removeRideById(rideId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A ride request was taken by another captain.'),
                backgroundColor: Colors.blueGrey,
              ),
            );
          }
        } else {
          if (!mounted) return;
          _refreshRides();
        }
      } else {}
    });
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
      isScrollControlled: true, // Allows sheet to take more height
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              // User Info
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  // backgroundImage: ride.userProfileImage != null ? NetworkImage(ride.userProfileImage!) : null,
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

              // Locations
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

              // Request Time
              if (ride.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 40.0), // Align with address text
                  child: Text(
                    'Requested: ${timeFormat.format(ride.createdAt!.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              const Divider(height: 20, thickness: 1),

              // Accept/Decline Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRideRequest(
                          ride.id), // Use new decline method
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
                      onPressed: () => _acceptRideRequest(
                          ride.id), // Use modified accept method
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
              const SizedBox(height: 10), // Padding at bottom
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

  void _toggleAvailability(bool value) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      final actualAvailability =
          await _captainService.toggleAvailability(value);

      if (!mounted) return;

      setState(() {
        isAvailable = actualAvailability;
        _isLoadingAvailability = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isAvailable ? 'You are now ONLINE' : 'You are now OFFLINE'),
          duration: Duration(seconds: 2),
        ),
      );

      if (!mounted) return;
      final provider = Provider.of<CaptainProvider>(context, listen: false);

      if (isAvailable) {
        if (!mounted) return;
        _startSendingLocationUpdates();
        await Future.delayed(const Duration(milliseconds: 2000));
        if (!mounted) return;
        await provider.fetchAvailableRides();
        if (!mounted) return;
        _moveToCurrentLocation();
      } else {
        if (!mounted) return;
        _stopSendingLocationUpdates();
        if (!mounted) return;
        provider.clearRides();
        if (!mounted) return;
        setState(() => _rideMarkers.clear());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startSendingLocationUpdates() {
    if (!mounted) return;
    _stopSendingLocationUpdates();

    _locationUpdatedTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (isAvailable) {
        _sendLocationUpdate();
      } else {
        _stopSendingLocationUpdates();
      }
    });
    if (isAvailable) {
      if (mounted) {
        _sendLocationUpdate();
      }
    }
  }

  void _stopSendingLocationUpdates() {
    _locationUpdatedTimer?.cancel();
    _locationUpdatedTimer = null;
  }

  Future<void> _sendLocationUpdate() async {
    if (!mounted) return;

    try {
      _currentLocationData = await _location.getLocation();
      if (!mounted) return;

      if (_currentLocationData != null &&
          _currentLocationData!.latitude != null &&
          _currentLocationData!.longitude != null) {
        bool success =
            await _captainService.updateCaptainLocation(_currentLocationData!);
        if (!mounted) return;

        if (!success) {}
      } else {}
    } catch (e) {
      if (mounted) {}
    }
  }
  // void _startSendingLocationUpdates() {
  //   print("TODO: Implement _startSendingLocationUpdates (e.g., start timer)");
  //   // Example: Start a timer to call _sendLocationUpdate periodically
  //   _locationUpdatedTimer?.cancel();
  //   _locationUpdatedTimer = Timer.periodic(Duration(seconds: 30), (timer) {
  //     _sendLocationUpdate();
  //   });
  // }

  // void _stopSendingLocationUpdates() {
  //   print("TODO: Implement _stopSendingLocationUpdates (e.g., cancel timer)");
  //   _locationUpdatedTimer?.cancel();
  // }

  // Future<void> _sendLocationUpdate() async {
  //   print("TODO: Implement _sendLocationUpdate (get location and send via HTTP)");
  //   try {
  //     _currentLocationData = await _location.getLocation();
  //     if (_currentLocationData?.latitude != null && _currentLocationData?.longitude != null) {
  //       // await _apiService.updateCaptainLocationHttp(
  //       //   widget.userId,
  //       //   _currentLocationData!.latitude!,
  //       //   _currentLocationData!.longitude!,
  //       //   // Add other relevant data like heading, speed if needed
  //       // );
  //       print("Location update sent via HTTP (simulated)");
  //     }
  //   } catch (e) {
  //     print("Error sending location update via HTTP: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Get CaptainProvider instance here to access its state
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
              if (isAvailable) // Only show refresh if online
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
              _buildHomeMapView(themeProvider), // Map view
              // Optional: Show loading indicator for rides over the map
              if (captainProvider.isLoading &&
                  captainProvider.availableRides.isEmpty)
                Center(child: CircularProgressIndicator()),
              // Optional: Show error message for rides over the map
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
    // Accept provider
    // ... existing loading and error checks using captainProvider.isLoading and captainProvider.errorMessage ...

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

    // --- Display Ride List using Provider data (Ride model) ---
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3, // Limit height
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
                // Use provider's list length
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
                // Use provider's list length
                itemCount: captainProvider.availableRides.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  // Get Ride object from provider's list
                  final ride = captainProvider.availableRides[index];
                  return ListTile(
                    leading:
                        const Icon(Icons.pin_drop_outlined, color: Colors.blue),
                    // Use Ride model fields
                    title: Text(ride.pickupAddress ?? 'Pickup Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(ride.dropAddress ?? 'Dropoff Location',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('₹${ride.fare.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)), // Use fare
                    onTap: () =>
                        _showRideDetailsBottomSheet(ride), // Pass Ride object
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
          // onMapCreated: (GoogleMapController controller) {
          //   mapController = controller;
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(31.1048, 77.1734),
            zoom: 11.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
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
                  SizedBox(height: 16), // Add some space before the button
                  SizedBox(
                    width: double.infinity, // Make the button take full width
                    child: ElevatedButton(
                      onPressed: _isLoadingAvailability
                          ? null
                          : () => _toggleAvailability(!isAvailable),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? Colors.red : Colors.green,
                        foregroundColor: Colors.white, // Ensure text is visible
                        shape: RoundedRectangleBorder(
                          // Use shape instead of borderRadius directly
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoadingAvailability // Use the correct state variable
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

  @override
  void dispose() {
    _rideCancelledSubscription?.cancel();
    _paymentCompletedSubscription?.cancel();
    _locationUpdatedTimer?.cancel();
    _newRideRequestSubscription?.cancel();
    super.dispose();
  }
}
