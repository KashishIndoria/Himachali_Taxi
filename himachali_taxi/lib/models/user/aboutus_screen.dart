import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/user/bottom_navigation_bar.dart';

class AboutUsScreen extends StatelessWidget {
  final String userId;

  const AboutUsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/taxilogo.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Himachali Taxi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Himachali Taxi - Your trusted transportation partner in Himachal Pradesh. '
              'We provide reliable taxi services across the beautiful landscapes of Himachal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const ListTile(
              leading: Icon(Icons.email),
              title: Text('Contact Us'),
              subtitle: Text('support@himachali_taxi.com'),
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('Call Us'),
              subtitle: Text('+91 1234567890'),
            ),
            const ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Find Us'),
              subtitle: Text('Shimla, Himachal Pradesh, India'),
            ),
            const SizedBox(height: 20),
            const Text(
              '© 2024 Himachali Taxi. All rights reserved.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3, userId: userId),
    );
  }
}
