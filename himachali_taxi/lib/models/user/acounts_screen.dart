import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:himachali_taxi/models/user/profile_screen.dart';
import 'package:himachali_taxi/models/user/profileimagehero.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:himachali_taxi/routers/approutes.dart';
import 'package:himachali_taxi/models/user/bottom_navigation_bar.dart';
import 'package:himachali_taxi/utils/sf_manager.dart';

class AccountsScreen extends StatefulWidget {
  final String userId;

  const AccountsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String? _profileImage;
  String _userName = '';
  bool _isLoading = true;
  late final String _baseUrl; // Use _baseUrl instead of _host

  @override
  void initState() {
    super.initState();
    _initializeBaseUrlAndFetchData(); // Call helper
  }

  // Helper function to initialize base URL and fetch data
  void _initializeBaseUrlAndFetchData() {
    try {
      _baseUrl = _getBaseUrl(); // Initialize _baseUrl
      _fetchUserData();
    } catch (e) {
      print("Error initializing accounts screen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Configuration error: ${e.toString()}")),
        );
      }
    }
  }

  // Function to get base URL from .env
  String _getBaseUrl() {
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      print("ERROR: BACKEND_URL not found in .env file.");
      throw Exception("BACKEND_URL not configured in .env file.");
    }
    print("AccountsScreen: Using BACKEND_URL: $baseUrl"); // Log the URL
    return baseUrl;
  }

  Future<void> _fetchUserData() async {
    // Ensure _baseUrl is initialized before fetching
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

    setState(() => _isLoading = true); // Set loading state at the beginning

    try {
      final String? sfToken = await SfManager.getToken();
      final String? userId = await SfManager.getUserId();
      if (sfToken == null || userId == null) {
        // Check userId as well
        throw Exception('Token or User ID not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/upload/profile?id=$userId'), // Use _baseUrl
        headers: {
          'Authorization': 'Bearer $sfToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];

        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            _profileImage = userData['profileImage'];
            _userName = userData['firstName'] ?? 'User';
          });
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to load user data: ${errorBody['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Ensure state is updated only if mounted
        setState(() => _isLoading = false); // Always set loading to false
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: ListView(
                children: [
                  // Profile Section
                  _buildProfileSection(context),

                  const SizedBox(height: 20),

                  // Account Settings Section
                  _buildSettingsGroup(context),

                  const SizedBox(height: 20),

                  // Support Section
                  _buildSupportGroup(context),

                  const SizedBox(height: 20),

                  // Logout Section
                  _buildLogoutButton(context),
                ],
              ),
            ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3, userId: userId),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    String userId = widget.userId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ListTile(
        onTap: () async {
          final String? sfToken = await SfManager.getToken();
          if (sfToken != null) {
            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userId: userId,
                  token: sfToken,
                ),
              ),
            ).then((_) => _fetchUserData());
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
            heroTag: 'profile-${widget.userId}',
            showEditButton: false,
          ),
        ),
        title: Text(
          _userName.isNotEmpty ? _userName : 'View Profile',
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
    );
  }

  Widget _buildSettingsGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: Icons.security,
          title: 'Privacy & Security',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: Icons.settings,
          title: 'App Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildSupportGroup(BuildContext context) {
    String userId = widget.userId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          title: 'Help Center',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'About Us',
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.aboutus,
            arguments: {'userId': userId},
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
