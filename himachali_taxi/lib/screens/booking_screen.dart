import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:himachali_taxi/provider/booking_provider.dart';
import 'package:himachali_taxi/models/booking_model.dart';
import 'package:himachali_taxi/widgets/loading_indicator.dart';
import 'package:himachali_taxi/widgets/error_dialog.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  double? _estimatedFare;
  bool _isCalculatingFare = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _calculateFare() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    setState(() {
      _isCalculatingFare = true;
    });

    // TODO: Implement fare calculation logic
    // This should call your backend API to calculate the fare
    await Future.delayed(const Duration(seconds: 1)); // Simulated API call
    setState(() {
      _estimatedFare = 150.0; // Example fare
      _isCalculatingFare = false;
    });
  }

  Future<void> _bookRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    try {
      await context.read<BookingProvider>().createBooking(
            pickupLocation: _pickupLocation!,
            dropoffLocation: _dropoffLocation!,
            pickupAddress: _pickupController.text,
            dropoffAddress: _dropoffController.text,
            estimatedFare: _estimatedFare ?? 0.0,
            paymentMethod: 'cash', // TODO: Add payment method selection
          );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/ride-status');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: 'Failed to book ride: ${e.toString()}',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map Preview
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target:
                              LatLng(31.1048, 77.1734), // Shimla coordinates
                          zoom: 14,
                        ),
                        markers: {
                          if (_pickupLocation != null)
                            Marker(
                              markerId: const MarkerId('pickup'),
                              position: _pickupLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                          if (_dropoffLocation != null)
                            Marker(
                              markerId: const MarkerId('dropoff'),
                              position: _dropoffLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                        },
                        onTap: (location) {
                          if (_pickupLocation == null) {
                            setState(() {
                              _pickupLocation = location;
                              _pickupController.text = 'Selected Location';
                            });
                          } else if (_dropoffLocation == null) {
                            setState(() {
                              _dropoffLocation = location;
                              _dropoffController.text = 'Selected Location';
                            });
                            _calculateFare();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pickup Location
                  TextFormField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on, color: Colors.green),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pickup location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropoff Location
                  TextFormField(
                    controller: _dropoffController,
                    decoration: const InputDecoration(
                      labelText: 'Dropoff Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter dropoff location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Estimated Fare
                  if (_isCalculatingFare)
                    const Center(child: CircularProgressIndicator())
                  else if (_estimatedFare != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Estimated Fare',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_estimatedFare!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Book Ride Button
                  ElevatedButton(
                    onPressed: _bookRide,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Book Ride',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
