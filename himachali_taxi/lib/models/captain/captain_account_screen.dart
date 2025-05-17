import 'dart:convert';
import 'dart:io' show Platform; // Import Platform
import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/models/captain/captain_profile_screen.dart';
import 'package:himachali_taxi/models/user/profileimagehero.dart';
import 'package:himachali_taxi/routers/approutes.dart';
import 'package:himachali_taxi/utils/sf_manager.dart';
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CaptainAccountScreen extends StatefulWidget {
  final String userId;
  final String token;

  const CaptainAccountScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _CaptainAccountScreenState createState() => _CaptainAccountScreenState();
}

class _CaptainAccountScreenState extends State<CaptainAccountScreen> {
  String? _profileImage;
  String _captainName = '';
  bool _isAvailable = false;
  bool _isOnline = false;
  bool _isLoading = true;
  final String _host = '192.168.177.195'; // Use the computer's local network IP directly

  @override
  void initState() {
    super.initState();
    _fetchCaptainData();
  }

  Future<void> _fetchCaptainData() async {
    try {
      final String? token = await SfManager.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse(
            'http://$_host:3000/api/captain/profile'), // Use host variable
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final captainData = responseData['captain'];

        setState(() {
          _profileImage = captainData['profileImage'];
          _captainName =
              '${captainData['firstName'] ?? ''} ${captainData['lastName'] ?? ''}';
          _isAvailable = captainData['isAvailable'] ?? false;
          _isOnline = captainData['isOnline'] ?? false;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load captain data');
      }
    } catch (e) {
      print('Error fetching captain data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch account data: $e')),
        );
      }
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      setState(() => _isLoading = true);

      final String? token = await SfManager.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.put(
        Uri.parse(
            'http://$_host:3000/api/captain/toggle-availability'), // Use host variable
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isAvailable': !_isAvailable}),
      );

      if (response.statusCode == 200) {
        await _fetchCaptainData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isAvailable
                  ? 'You are now offline'
                  : 'You are now available for rides'),
              backgroundColor: _isAvailable ? Colors.red : Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to update availability');
      }
    } catch (e) {
      print('Error toggling availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      final String? token = await SfManager.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('http://$_host:3000/api/auth/logout'), // Use host variable
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await SfManager.clearToken();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (route) => false);
        }
      } else {
        throw Exception('Failed to logout');
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
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

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Captain Account',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: primaryCaptainColor,
            elevation: 0,
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryCaptainColor))
              : RefreshIndicator(
                  onRefresh: _fetchCaptainData,
                  child: ListView(
                    children: [
                      // Profile Section with Availability Toggle
                      _buildProfileSection(context, primaryCaptainColor),

                      const SizedBox(height: 20),

                      // Account Settings Section
                      _buildSettingsGroup(context, themeProvider),

                      const SizedBox(height: 20),

                      // Earnings & Stats Section
                      _buildEarningsGroup(context, themeProvider),

                      const SizedBox(height: 20),

                      // Support Section
                      _buildSupportGroup(context, themeProvider),

                      const SizedBox(height: 20),

                      // Logout Section
                      _buildLogoutButton(context, themeProvider),
                    ],
                  ),
                ),
          bottomNavigationBar: CaptainNavBar(
            currentIndex: 3,
            userId: widget.userId,
            token: widget.token,
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () async {
              final String? token = await SfManager.getToken();
              if (token != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaptainProfileScreen(
                      userId: widget.userId,
                      token: token,
                    ),
                  ),
                ).then((_) => _fetchCaptainData());
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ProfileImageHero(
                imageUrl: _profileImage,
                radius: 30,
                heroTag: 'captain-${widget.userId}',
                showEditButton: false,
              ),
            ),
            title: Text(
              _captainName.isNotEmpty ? _captainName : 'Captain Profile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Tap to view and edit your profile',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Availability Switch
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAvailable ? 'You are Online' : 'You are Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _isAvailable
                          ? 'You can receive ride requests'
                          : 'Go online to receive ride requests',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) => _toggleAvailability(),
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
      BuildContext context, ThemeProvider themeProvider) {
    final textColor =
        themeProvider.isDarkMode ? DarkColors.text : LightColors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        _buildSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage ride alerts and offers',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.credit_card,
          title: 'Payment Methods',
          subtitle: 'Manage your payout accounts',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.settings,
          title: 'App Settings',
          subtitle: 'Change language, theme and more',
          onTap: () {},
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildEarningsGroup(
      BuildContext context, ThemeProvider themeProvider) {
    final textColor =
        themeProvider.isDarkMode ? DarkColors.text : LightColors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Earnings & Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        _buildSettingsTile(
          icon: Icons.monetization_on_outlined,
          title: 'Earnings',
          subtitle: 'View your ride earnings and payouts',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.bar_chart,
          title: 'Performance',
          subtitle: 'Your ratings and ride statistics',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.history,
          title: 'Ride History',
          subtitle: 'View your completed rides',
          onTap: () {},
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildSupportGroup(BuildContext context, ThemeProvider themeProvider) {
    final textColor =
        themeProvider.isDarkMode ? DarkColors.text : LightColors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        _buildSettingsTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with your account and rides',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'About Us',
          subtitle: 'Learn about Himachali Taxi',
          onTap: () {},
          textColor: textColor,
        ),
        _buildSettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          onTap: () {},
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeProvider themeProvider) {
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;
    final onPrimaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.onPrimaryCaptain
        : LightColors.onPrimaryCaptain;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimaryCaptainColor,
          backgroundColor: primaryCaptainColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primaryCaptainColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: onPrimaryCaptainColor),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onPrimaryCaptainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor.withOpacity(0.8)),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: textColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}
