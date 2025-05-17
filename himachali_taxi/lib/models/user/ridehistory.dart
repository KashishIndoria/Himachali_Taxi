import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';

class RidesHistoryScreen extends StatefulWidget {
  final String userId;
  final String token;

  const RidesHistoryScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<RidesHistoryScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesHistoryScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Rides',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildUpcomingRides(),
                        _buildRideHistory(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 1,
        userId: widget.userId,
      ),
    );
  }

  Widget _buildUpcomingRides() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 0, // Replace with actual data
      itemBuilder: (context, index) {
        return const Card(
          child: ListTile(
            title: Text('No upcoming rides'),
          ),
        );
      },
    );
  }

  Widget _buildRideHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 0, // Replace with actual data
      itemBuilder: (context, index) {
        return const Card(
          child: ListTile(
            title: Text('No ride history'),
          ),
        );
      },
    );
  }
}
