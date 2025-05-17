import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/user/bottom_navigation_bar.dart';

class ServicesScreen extends StatelessWidget {
  final String userId;

  const ServicesScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...existing code...
      bottomNavigationBar: CustomNavBar(currentIndex: 1, userId: userId),
    );
  }
}
