import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';
import '../widgets/ride_history_item.dart';

class RideHistoryScreen extends StatefulWidget {
  final RideService rideService;

  const RideHistoryScreen({
    Key? key,
    required this.rideService,
  }) : super(key: key);

  @override
  _RideHistoryScreenState createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Ride> _rides = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  RideService get _rideService => widget.rideService;

  @override
  void initState() {
    super.initState();
    _loadRides();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadRides();
      }
    }
  }

  Future<void> _loadRides() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideService.getRideHistory(
        page: _currentPage,
        limit: _pageSize,
      );

      setState(() {
        _rides.addAll(rides);
        _currentPage++;
        _hasMore = rides.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: $e')),
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _rides.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _rides.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rides yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _rides.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _rides.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final ride = _rides[index];
                  return RideHistoryItem(
                    ride: ride,
                    onTap: () {
                      // Navigate to ride details screen
                      // Navigator.pushNamed(context, '/ride-details', arguments: ride);
                    },
                  );
                },
              ),
      ),
    );
  }
}
