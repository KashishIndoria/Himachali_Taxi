import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himachali_taxi/models/user/bottom_navigation_bar.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geo; // Add this import
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Add this import
import '../../provider/socket_provider.dart';
import '../../utils/themes/themeprovider.dart';
import '../../utils/themes/colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum RideState { idle, searching, accepted, ongoing, completed, cancelled }

class HomeScreen extends StatefulWidget {
  final String userId;
  final String token;

  const HomeScreen({Key? key, required this.userId, required this.token})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  BitmapDescriptor? _captainIcon; // Uncomment captain icon variable

  // Ride State Management
  RideState _rideState = RideState.idle;
  Map<String, dynamic>? _activeRideDetails;
  Map<String, dynamic>? _assignedCaptainDetails;
  StreamSubscription? _captainLocationSubscription;
  StreamSubscription? _rideAcceptedSubscription;
  StreamSubscription? _rideCancelledSubscription;
  // Add other subscriptions as needed (rideCompleted, etc.)

  late SocketProvider _socketProvider;

  String googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(32.2245, 76.1566), // Himachal Pradesh coordinates
    zoom: 15,
  );

  List<String> _fromSuggestions = [];
  List<String> _destinationSuggestions = [];
  LatLng? _fromLatLng;
  LatLng? _destinationLatLng;

  // --- START: Add OverlayPortal controllers ---
  final OverlayPortalController _fromSuggestionsController =
      OverlayPortalController();
  final OverlayPortalController _destinationSuggestionsController =
      OverlayPortalController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  final LayerLink _fromLayerLink = LayerLink();
  final LayerLink _destinationLayerLink = LayerLink();
  // --- END: Add OverlayPortal controllers ---

  // --- START: Add Polyline variables ---
  Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  // --- END: Add Polyline variables ---

  @override
  void initState() {
    super.initState();
    _socketProvider = Provider.of<SocketProvider>(context, listen: false);
    _loadMarkerIcons(); // Uncomment the call to load the icon
    _getCurrentLocation();
    _setupSocketListeners();

    // --- START: Add FocusNode listeners ---
    _fromFocusNode.addListener(() {
      if (!_fromFocusNode.hasFocus) {
        _fromSuggestionsController.hide();
      }
    });
    _destinationFocusNode.addListener(() {
      if (!_destinationFocusNode.hasFocus) {
        _destinationSuggestionsController.hide();
      }
    });
    // --- END: Add FocusNode listeners ---
  }

  @override
  void dispose() {
    _fromController.dispose();
    _destinationController.dispose();
    _mapController?.dispose();
    // Cancel all stream subscriptions
    _captainLocationSubscription?.cancel();
    _rideAcceptedSubscription?.cancel();
    _rideCancelledSubscription?.cancel();
    // --- START: Dispose FocusNodes ---
    _fromFocusNode.dispose();
    _destinationFocusNode.dispose();
    // --- END: Dispose FocusNodes ---
    super.dispose();
  }

  void _setupSocketListeners() {
    // Listen for captain location updates
    _captainLocationSubscription =
        _socketProvider.socketService.captainLocationUpdates.listen((data) {
      final Map<String, dynamic>? dataMap = data as Map<String, dynamic>?;
      if (dataMap != null &&
          dataMap['captainId'] != null &&
          dataMap['location'] != null) {
        _updateCaptainMarker(dataMap);
      }
    });

    // Listen for ride acceptance
    _rideAcceptedSubscription =
        _socketProvider.socketService.rideAcceptedUpdates.listen((data) {
      final Map<String, dynamic>? dataMap = data as Map<String, dynamic>?;
      if (dataMap != null &&
          dataMap['rideId'] != null &&
          dataMap['captainId'] != null) {
        print("Ride Accepted Data: $dataMap");
        setState(() {
          _rideState = RideState.accepted;
          _activeRideDetails = dataMap;
          _assignedCaptainDetails = {
            'id': dataMap['captainId'],
            'name': dataMap['captainName'],
            'phone': dataMap['captainPhone'],
            'rating': dataMap['captainRating'],
            'vehicle': dataMap['vehicleDetails'],
          };
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_assignedCaptainDetails?['name'] ?? 'Driver'} accepted your ride!'),
            backgroundColor: Colors.green,
          ),
        );
        _markers.removeWhere((m) =>
            m.markerId.value == 'from' || m.markerId.value == 'destination');
      }
    });

    // Listen for ride cancellation
    _rideCancelledSubscription =
        _socketProvider.socketService.rideCancelledUpdates.listen((data) {
      final Map<String, dynamic>? dataMap = data as Map<String, dynamic>?;
      if (dataMap != null && dataMap['rideId'] != null) {
        if (_activeRideDetails != null &&
            dataMap['rideId'] == _activeRideDetails!['rideId']) {
          print("Ride Cancelled Data: $dataMap");
          setState(() {
            _rideState = RideState.cancelled;
            _activeRideDetails = null;
            _assignedCaptainDetails = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride cancelled: ${dataMap['reason'] ?? ''}'),
              backgroundColor: Colors.orange,
            ),
          );
          _markers.removeWhere((m) => m.markerId.value != 'current_location');
        }
      }
    });
  }

  void _updateCaptainMarker(Map<String, dynamic> captainData) {
    // This function now does nothing, preventing captain markers from being added/updated.
    // print(
    //     "Received captain update for ${captainData['captainId']}, but marker display is disabled.");

    // --- Original code uncommented ---
    final String captainId = captainData['captainId'];
    final locationData = captainData['location'];
    final List<dynamic>? coords = locationData['coordinates'];
    final double? heading = locationData['heading']?.toDouble();

    if (coords != null && coords.length == 2) {
      final LatLng position = LatLng(coords[1], coords[0]);

      bool shouldUpdateMarker =
          (_rideState == RideState.accepted || _rideState == RideState.ongoing)
              ? (_assignedCaptainDetails != null &&
                  _assignedCaptainDetails!['id'] == captainId)
              : _rideState == RideState.idle;

      // The check for _captainIcon would now fail anyway, but explicitly removing logic
      if (shouldUpdateMarker && _captainIcon != null) {
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'captain_$captainId');
          _markers.add(
            Marker(
              markerId: MarkerId('captain_$captainId'),
              position: position,
              icon: _captainIcon!,
              rotation: heading ?? 0.0,
              anchor: const Offset(0.5, 0.5),
              infoWindow: InfoWindow(
                title: _assignedCaptainDetails != null &&
                        _assignedCaptainDetails!['id'] == captainId
                    ? _assignedCaptainDetails!['name'] ?? 'Your Driver'
                    : 'Nearby Captain',
              ),
            ),
          );
        });
      }
    }
    // --- End of original code ---
  }

  // --- START: Add load marker icons function ---
  Future<void> _loadMarkerIcons() async {
    // Load the custom captain icon
    _captainIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
      'assets/images/taxi.png', // Make sure this path is correct
    );
    // You can load other icons here if needed
    setState(() {}); // Update the state if needed after loading
  }
  // --- END: Add load marker icons function ---

  Future<void> _getCurrentLocation() async {
    final location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      setState(() => _isLoading = true);

      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(locationData.latitude!, locationData.longitude!),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(locationData.latitude!, locationData.longitude!),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      return []; // Don't call API for empty input
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$googleApiKey&components=country:in'; // Added country bias for India
    // --- START: Add Logging ---
    print('Autocomplete URL: $url');
    // --- END: Add Logging ---
    try {
      final response = await http.get(Uri.parse(url));
      // --- START: Add Logging ---
      print('Autocomplete Response Status: ${response.statusCode}');
      // print('Autocomplete Response Body: ${response.body}'); // Optional: Log full body for deep debug
      // --- END: Add Logging ---
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'OK') {
          final predictions = (jsonResponse['predictions'] as List)
              .map((p) => p['description'] as String)
              .toList();
          print(
              'Autocomplete Success: Found ${predictions.length} suggestions');
          return predictions;
        } else {
          print(
              'Autocomplete API Error: Status: ${jsonResponse['status']}, Error: ${jsonResponse['error_message']}');
        }
      } else {
        print('Autocomplete HTTP Error: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('Autocomplete Exception: $e');
    }
    return []; // Return empty list on failure
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';
    // --- START: Add Logging ---
    print('Geocoding URL: $url');
    // --- END: Add Logging ---
    try {
      final response = await http.get(Uri.parse(url));
      // --- START: Add Logging ---
      print('Geocoding Response Status: ${response.statusCode}');
      print('Geocoding Response Body: ${response.body}');
      // --- END: Add Logging ---
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'OK' &&
            jsonResponse['results'].isNotEmpty) {
          final location = jsonResponse['results'][0]['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          print('Geocoding Success: Lat: $lat, Lng: $lng'); // Log success
          return LatLng(lat, lng);
        } else {
          print(
              'Geocoding API Error: Status: ${jsonResponse['status']}, Error: ${jsonResponse['error_message']}'); // Log API error
        }
      } else {
        print(
            'Geocoding HTTP Error: Status Code ${response.statusCode}'); // Log HTTP error
      }
    } catch (e) {
      print('Geocoding Exception: $e'); // Log any other exceptions
    }
    return null; // Return null if anything fails
  }

  Future<void> _setPickupToCurrentLocation() async {
    if (_currentLocation == null) {
      // Optionally re-fetch if null, though it should be fetched on init
      await _getCurrentLocation();
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true); // Show loading indicator

    try {
      final lat = _currentLocation!.latitude!;
      final lon = _currentLocation!.longitude!;
      List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        // Format a readable address (customize as needed)
        String address =
            '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';

        _fromController.text = address;
        _fromLatLng = LatLng(lat, lon);
        _fromSuggestions = []; // Clear suggestions

        // Update map marker
        _markers.removeWhere((m) => m.markerId.value == 'from');
        _markers.add(
          Marker(
            markerId: const MarkerId('from'),
            position: _fromLatLng!,
            infoWindow: const InfoWindow(title: 'Current Location (From)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen), // Optional: different color
          ),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLng(_fromLatLng!));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not find address for current location.')),
        );
      }
    } catch (e) {
      print('Error during reverse geocoding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error finding address.')),
      );
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  void _onFromChanged(String value) async {
    // --- START: Clear LatLng and Route on change ---
    if (_fromLatLng != null) {
      setState(() {
        _fromLatLng = null;
        _polylines.clear();
        _markers.removeWhere((m) => m.markerId.value == 'from');
      });
    }
    // --- END: Clear LatLng and Route on change ---
    final suggestions = await _fetchSuggestions(value);
    setState(() {
      _fromSuggestions = suggestions;
    });
    // --- START: Control OverlayPortal ---
    if (_fromSuggestions.isNotEmpty && _fromFocusNode.hasFocus) {
      _fromSuggestionsController.show();
    } else {
      _fromSuggestionsController.hide();
    }
    // --- END: Control OverlayPortal ---
  }

  void _onDestinationChanged(String value) async {
    // --- START: Clear LatLng and Route on change ---
    if (_destinationLatLng != null) {
      setState(() {
        _destinationLatLng = null;
        _polylines.clear();
        _markers.removeWhere((m) => m.markerId.value == 'destination');
      });
    }
    // --- END: Clear LatLng and Route on change ---
    final suggestions = await _fetchSuggestions(value);
    setState(() {
      _destinationSuggestions = suggestions;
    });
    // --- START: Control OverlayPortal ---
    if (_destinationSuggestions.isNotEmpty && _destinationFocusNode.hasFocus) {
      _destinationSuggestionsController.show();
    } else {
      _destinationSuggestionsController.hide();
    }
    // --- END: Control OverlayPortal ---
  }

  void _onFromSuggestionTap(String suggestion) async {
    // --- START: Hide OverlayPortal ---
    _fromSuggestionsController.hide();
    _fromFocusNode.unfocus(); // Hide keyboard
    // --- END: Hide OverlayPortal ---
    _fromController.text = suggestion;
    _fromSuggestions = [];
    // --- START: Add Logging ---
    print('Tapped From Suggestion: $suggestion');
    setState(() => _isLoading = true); // Show loading indicator
    // --- END: Add Logging ---
    _fromLatLng = await _getLatLngFromAddress(suggestion);
    // --- START: Add Logging ---
    print('Resulting From LatLng: $_fromLatLng');
    setState(() => _isLoading = false); // Hide loading indicator
    // --- END: Add Logging ---
    if (_fromLatLng != null) {
      setState(() {
        _markers.removeWhere(
            (m) => m.markerId.value == 'from'); // Remove previous marker
        _markers.add(
          Marker(
            markerId: const MarkerId('from'),
            position: _fromLatLng!,
            infoWindow:
                InfoWindow(title: 'From: $suggestion'), // Update info window
          ),
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_fromLatLng!));
      // --- START: Try drawing route ---
      _drawRoute();
      // --- END: Try drawing route ---
    } else {
      // Optionally show an error if geocoding failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find coordinates for $suggestion')),
      );
    }
    setState(() {}); // Update UI regardless
  }

  void _onDestinationSuggestionTap(String suggestion) async {
    // --- START: Hide OverlayPortal ---
    _destinationSuggestionsController.hide();
    _destinationFocusNode.unfocus(); // Hide keyboard
    // --- END: Hide OverlayPortal ---
    _destinationController.text = suggestion;
    _destinationSuggestions = [];
    // --- START: Add Logging ---
    print('Tapped Destination Suggestion: $suggestion');
    setState(() => _isLoading = true); // Show loading indicator
    // --- END: Add Logging ---
    _destinationLatLng = await _getLatLngFromAddress(suggestion);
    // --- START: Add Logging ---
    print('Resulting Destination LatLng: $_destinationLatLng');
    setState(() => _isLoading = false); // Hide loading indicator
    // --- END: Add Logging ---
    if (_destinationLatLng != null) {
      setState(() {
        _markers.removeWhere(
            (m) => m.markerId.value == 'destination'); // Remove previous marker
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLatLng!,
            infoWindow:
                InfoWindow(title: 'To: $suggestion'), // Update info window
          ),
        );
      });
      _mapController
          ?.animateCamera(CameraUpdate.newLatLng(_destinationLatLng!));
      // --- START: Try drawing route ---
      _drawRoute();
      // --- END: Try drawing route ---
    } else {
      // Optionally show an error if geocoding failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find coordinates for $suggestion')),
      );
    }
    setState(() {}); // Update UI regardless
  }

  double _calculateEstimatedFare(LatLng pickup, LatLng dropoff) {
    const double baseFare = 50.0;
    const double ratePerKm = 15.0;

    final double distanceInKm = calculateDistance(pickup, dropoff);

    double fare = baseFare + (distanceInKm * ratePerKm);
    return fare < baseFare ? baseFare : fare;
  }

  void _handleRideRequest() async {
    // --- START: Add Logging ---
    print('Handling ride request...');
    print('From LatLng: $_fromLatLng');
    print('Destination LatLng: $_destinationLatLng');
    // --- END: Add Logging ---

    if (_fromLatLng == null || _destinationLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select valid pickup and drop-off locations.')),
      );
      return;
    }

    setState(() {
      _rideState = RideState.searching;
      _isLoading = true;
    });

    double estimatedFare =
        _calculateEstimatedFare(_fromLatLng!, _destinationLatLng!);

    final rideData = {
      'userId': widget.userId,
      'pickupLocation': {
        'latitude': _fromLatLng!.latitude,
        'longitude': _fromLatLng!.longitude,
        'address': _fromController.text,
      },
      'dropLocation': {
        'latitude': _destinationLatLng!.latitude,
        'longitude': _destinationLatLng!.longitude,
        'address': _destinationController.text,
      },
      'fare': estimatedFare,
      'paymentMethod': 'cash',
    };

    print("Requesting Ride: $rideData");
    _socketProvider.socketService.requestRide(rideData);
  }

  // --- START: Add cancel search function ---
  void _cancelRideSearch() {
    // TODO: Implement backend notification if necessary (e.g., emit a socket event)
    // For now, just reset the UI state
    setState(() {
      _rideState = RideState.idle;
      _isLoading = false;
    });
    print("Ride search cancelled by user.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride search cancelled.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  // --- END: Add cancel search function ---

  // --- START: New function to draw route ---
  Future<void> _drawRoute() async {
    // Only draw if both points are available
    if (_fromLatLng == null || _destinationLatLng == null) {
      print('Cannot draw route: Missing origin or destination coordinates.');
      // Ensure any previous route is cleared if one point becomes null
      if (_polylines.isNotEmpty) {
        setState(() {
          _polylines.clear();
        });
      }
      return;
    }

    print('Drawing route from $_fromLatLng to $_destinationLatLng');
    setState(() => _isLoading = true); // Show loading indicator

    try {
      // --- START: Correct Polyline Call ---
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(_fromLatLng!.latitude, _fromLatLng!.longitude),
        destination: PointLatLng(
            _destinationLatLng!.latitude, _destinationLatLng!.longitude),
        mode: TravelMode.driving,
        // No API key here
      );
      // Pass API key as first argument, request object as named argument
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: googleApiKey, request: request);
      // --- END: Correct Polyline Call ---

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });

        Polyline polyline = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue, // Customize color
          points: polylineCoordinates,
          width: 5, // Customize width
        );

        setState(() {
          _polylines.clear(); // Clear previous routes
          _polylines.add(polyline);
          print(
              'Route drawn successfully with ${polylineCoordinates.length} points.');
        });

        // Optional: Adjust map bounds to fit the route
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList(polylineCoordinates),
            50, // Padding
          ),
        );
      } else {
        print('Directions API Error: ${result.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not draw route: ${result.errorMessage}')),
        );
        // Clear any existing route if API fails
        setState(() {
          _polylines.clear();
        });
      }
    } catch (e) {
      print('Error drawing route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while drawing the route.')),
      );
      setState(() {
        _polylines.clear();
      });
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }
  // --- END: New function to draw route ---

  // --- START: Helper function for bounds ---
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }
  // --- END: Helper function for bounds ---

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor =
        themeProvider.isDarkMode ? DarkColors.primary : LightColors.primary;
    final onPrimaryColor =
        themeProvider.isDarkMode ? DarkColors.onPrimary : LightColors.onPrimary;
    final dividerColor =
        themeProvider.isDarkMode ? DarkColors.divider : LightColors.divider;
    final textColor =
        themeProvider.isDarkMode ? DarkColors.text : LightColors.text;
    final subtextColor =
        themeProvider.isDarkMode ? DarkColors.subtext : LightColors.subtext;
    final shadowColor =
        themeProvider.isDarkMode ? DarkColors.shadow : LightColors.shadow;
    final surfaceColor =
        themeProvider.isDarkMode ? DarkColors.surface : LightColors.surface;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: Image.asset(
                "assets/images/taxilogo.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              "Himachali Taxi",
              style: TextStyle(color: onPrimaryColor),
            ),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines, // --- Add this line ---
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                  ),
                );
              }
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_rideState == RideState.idle)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 4,
                              width: 50,
                              decoration: BoxDecoration(
                                color: dividerColor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Book a ride',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // --- START: Replace Stack with OverlayPortal ---
                          OverlayPortal(
                            controller: _fromSuggestionsController,
                            overlayChildBuilder: (BuildContext context) {
                              return CompositedTransformFollower(
                                link: _fromLayerLink,
                                showWhenUnlinked: false,
                                offset: const Offset(0.0,
                                    5.0), // Adjust vertical offset as needed
                                child: Material(
                                  elevation: 4.0,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    // Match padding
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxHeight: 200), // Limit height
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        children: _fromSuggestions
                                            .map((suggestion) => ListTile(
                                                  title: Text(suggestion),
                                                  onTap: () =>
                                                      _onFromSuggestionTap(
                                                          suggestion),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: CompositedTransformTarget(
                              link: _fromLayerLink,
                              child: TextField(
                                controller: _fromController,
                                focusNode: _fromFocusNode, // Assign FocusNode
                                decoration: InputDecoration(
                                  labelText: 'From',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on,
                                      color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.my_location,
                                        color: primaryColor),
                                    tooltip: 'Use Current Location',
                                    onPressed: _setPickupToCurrentLocation,
                                  ),
                                ),
                                onChanged: _onFromChanged,
                              ),
                            ),
                          ),
                          // --- END: Replace Stack with OverlayPortal ---
                          const SizedBox(height: 10),
                          // --- START: Replace Stack with OverlayPortal ---
                          OverlayPortal(
                            controller: _destinationSuggestionsController,
                            overlayChildBuilder: (BuildContext context) {
                              return CompositedTransformFollower(
                                link: _destinationLayerLink,
                                showWhenUnlinked: false,
                                offset: const Offset(0.0,
                                    5.0), // Adjust vertical offset as needed
                                child: Material(
                                  elevation: 4.0,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    // Match padding
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxHeight: 200), // Limit height
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        children: _destinationSuggestions
                                            .map((suggestion) => ListTile(
                                                  title: Text(suggestion),
                                                  onTap: () =>
                                                      _onDestinationSuggestionTap(
                                                          suggestion),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: CompositedTransformTarget(
                              link: _destinationLayerLink,
                              child: TextField(
                                controller: _destinationController,
                                focusNode:
                                    _destinationFocusNode, // Assign FocusNode
                                decoration: InputDecoration(
                                  labelText: 'Destination location',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on,
                                      color: primaryColor),
                                ),
                                onChanged: _onDestinationChanged,
                              ),
                            ),
                          ),
                          // --- END: Replace Stack with OverlayPortal ---
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleRideRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                'Book a ride',
                                style: TextStyle(
                                    color: onPrimaryColor, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_rideState == RideState.searching)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: surfaceColor.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    const Text("Searching for nearby drivers..."),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _cancelRideSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if ((_rideState == RideState.accepted ||
                  _rideState == RideState.ongoing) &&
              _assignedCaptainDetails != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          _rideState == RideState.accepted
                              ? "Driver on the way!"
                              : "Ride in Progress",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text(_assignedCaptainDetails!['name'] ?? 'N/A'),
                        subtitle: Text(
                            '${_assignedCaptainDetails!['vehicle']?['model'] ?? 'Taxi'} - ${_assignedCaptainDetails!['vehicle']?['plateNumber'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                                ' ${_assignedCaptainDetails!['rating']?.toStringAsFixed(1) ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(icon: Icon(Icons.call), onPressed: () {}),
                          IconButton(
                              icon: Icon(Icons.message), onPressed: () {}),
                          TextButton(
                            child: Text("Cancel Ride",
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              _socketProvider.socketService.cancelRideUser(
                                  widget.userId,
                                  _activeRideDetails!['rideId'],
                                  "Cancelled by user");
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _rideState == RideState.idle
          ? CustomNavBar(currentIndex: 0, userId: widget.userId)
          : null,
    );
  }
}

double calculateDistance(LatLng latLng1, LatLng latLng2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((latLng2.latitude - latLng1.latitude) * p) / 2 +
      c(latLng1.latitude * p) *
          c(latLng2.latitude * p) *
          (1 - c((latLng2.longitude - latLng1.longitude) * p)) /
          2;
  return 12742 * asin(sqrt(a));
}
