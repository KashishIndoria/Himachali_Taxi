import 'dart:convert';
import 'dart:io' show Platform; // Import Platform
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/utils/sf_manager.dart'; // Import SfManager
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class CaptainEarningsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const CaptainEarningsScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _CaptainEarningsScreenState createState() => _CaptainEarningsScreenState();
}

class _CaptainEarningsScreenState extends State<CaptainEarningsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _earningsData = {};
  int _selectedPeriod = 7; // Default to 7 days
  late final String _baseUrl; // Use baseUrl from .env

  @override
  void initState() {
    super.initState();
    _initializeBaseUrlAndFetchData();
  }

  // Helper to initialize base URL and fetch data
  void _initializeBaseUrlAndFetchData() {
    try {
      _baseUrl = _getBaseUrl();
      _fetchEarningsData();
    } catch (e) {
      print("Error initializing earnings screen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Configuration error: ${e.toString()}")),
        );
      }
    }
  }

  // Helper to get Base URL from .env
  String _getBaseUrl() {
    final baseUrl = dotenv.env['BASE_URL'] ?? dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      print("ERROR: BASE_URL not found in .env file.");
      throw Exception("BASE_URL not configured in .env file.");
    }
    return baseUrl;
  }

  Future<void> _fetchEarningsData() async {
    // Ensure baseUrl is initialized
    if (_baseUrl.isEmpty) {
      print("Base URL not initialized. Cannot fetch data.");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Configuration error: Base URL missing.")),
        );
      }
      return;
    }

    if (!mounted) return; // Check if mounted before starting async operation
    setState(() => _isLoading = true); // Line 63 (original error location)

    try {
      final captainToken =
          await SfManager.getToken(); // Fetch token using SfManager
      if (captainToken == null) {
        throw Exception("Authentication token not found.");
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/captain/earnings?period=$_selectedPeriod'), // Use _baseUrl
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $captainToken', // Use fetched token
        },
      );

      if (!mounted) return; // Check again after await

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Add mounted check implicitly via the outer check
          _earningsData = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load earnings data: ${response.body}');
      }
    } catch (e) {
      print('Error fetching earnings data: $e');
      if (mounted) {
        // Add mounted check here
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch earnings data: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final primaryCaptainColor = themeProvider.isDarkMode
            ? DarkColors.primaryCaptain
            : LightColors.primaryCaptain;
        final backgroundColor = themeProvider.isDarkMode
            ? DarkColors.background
            : LightColors.background;
        final cardColor =
            themeProvider.isDarkMode ? DarkColors.surface : LightColors.surface;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: primaryCaptainColor,
            title:
                const Text('Earnings', style: TextStyle(color: Colors.white)),
            elevation: 0,
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryCaptainColor))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPeriodButton(
                                '7 Days', 7, primaryCaptainColor),
                            _buildPeriodButton(
                                '30 Days', 30, primaryCaptainColor),
                            _buildPeriodButton(
                                '90 Days', 90, primaryCaptainColor),
                          ],
                        ),
                      ),

                      // Earnings summary card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: cardColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Earnings (Last $_selectedPeriod Days)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_earningsData['totalEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryCaptainColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildEarningsStat(
                                      'Rides',
                                      '${_earningsData['totalRides'] ?? 0}',
                                      Icons.directions_car,
                                    ),
                                    _buildEarningsStat(
                                      'Average',
                                      '₹${(_earningsData['totalEarnings'] ?? 0) / (_earningsData['totalRides'] ?? 1) > 0 ? ((_earningsData['totalEarnings'] ?? 0) / (_earningsData['totalRides'] ?? 1)).toStringAsFixed(0) : '0'}',
                                      Icons.add_chart,
                                    ),
                                    _buildEarningsStat(
                                      'Hours',
                                      '${_earningsData['totalHours'] ?? 0}',
                                      Icons.access_time,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Earnings chart
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: cardColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Earnings Trend',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: _buildEarningsChart(
                                    _earningsData['earningsByDay'],
                                    primaryCaptainColor,
                                    themeProvider.isDarkMode,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Recent transactions
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: cardColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildRecentTransactions(
                                  _earningsData['recentTransactions'] ?? [],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: CaptainNavBar(
            currentIndex: 2,
            userId: widget.userId,
            token: widget.token,
          ),
        );
      },
    );
  }

  Widget _buildPeriodButton(String label, int days, Color primaryColor) {
    final isSelected = _selectedPeriod == days;

    return GestureDetector(
      onTap: () {
        if (!mounted) return; // Add mounted check before setState
        setState(() => _selectedPeriod = days);
        _fetchEarningsData(); // Refetch data for the new period
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart(
      Map<String, dynamic>? earningsByDay, Color color, bool isDarkMode) {
    if (earningsByDay == null || earningsByDay.isEmpty) {
      return Center(child: Text('No earnings data available'));
    }

    final List<FlSpot> spots = [];
    final List<String> dates = [];
    int index = 0;

    // Sort dates
    final sortedDates = earningsByDay.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    for (final date in sortedDates) {
      final amount = earningsByDay[date] is num ? earningsByDay[date] : 0.0;
      spots.add(FlSpot(index.toDouble(), amount.toDouble()));
      dates.add(DateFormat('MMM d').format(DateTime.parse(date)));
      index++;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < dates.length && index % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dates[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No recent transactions'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(
              transaction['type'] == 'ride'
                  ? Icons.directions_car
                  : Icons.attach_money,
            ),
          ),
          title: Text(transaction['description'] ?? 'Transaction'),
          subtitle: Text(
            DateFormat('MMM d, yyyy').format(
              DateTime.parse(transaction['date'] ?? DateTime.now().toString()),
            ),
          ),
          trailing: Text(
            '₹${transaction['amount']?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  transaction['type'] == 'payout' ? Colors.red : Colors.green,
            ),
          ),
        );
      },
    );
  }
}
