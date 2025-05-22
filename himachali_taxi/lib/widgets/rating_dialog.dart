import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../services/api_service.dart';

class RatingDialog extends StatefulWidget {
  final String rideId;

  const RatingDialog({
    super.key,
    required this.rideId,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 3.0; //
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService(); // Instance of your service

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await _apiService.submitRideRating(
        rideId: widget.rideId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        // Check if the widget is still in the tree
        if (success) {
          Navigator.of(context).pop(true); // Pop dialog and indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating submitted successfully!')),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to submit rating. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
      print("Error in _submitRating: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Ride'),
      content: SingleChildScrollView(
        // Prevents overflow if keyboard appears
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Optional: Display driver info if passed
            // Text("How was your ride with ${widget.driverName}?"),
            // const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false, // Or true if you allow half stars
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add an optional comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false), // Indicate cancellation
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
