import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/captain/captain_profile_screen.dart';
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/utils/sf_manager.dart';
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

class CaptainSettingsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const CaptainSettingsScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _CaptainSettingsScreenState createState() => _CaptainSettingsScreenState();
}

class _CaptainSettingsScreenState extends State<CaptainSettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _isDarkMode = themeProvider.isDarkMode;
      // Load other settings from shared preferences if needed
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SfManager.clearAll();
              // Navigate to login screen and clear stack
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
        final textColor =
            themeProvider.isDarkMode ? DarkColors.text : LightColors.text;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryCaptainColor,
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: ListView(
            children: [
              // Account Settings
              _buildSectionHeader('Account Settings'),
              _buildSettingItem(
                icon: Icons.person,
                title: 'My Profile',
                subtitle: 'View and edit your profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CaptainProfileScreen(
                        userId: widget.userId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                cardColor: cardColor,
              ),
              _buildSettingItem(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                trailing: Switch(
                  value: _notificationsEnabled,
                  activeColor: primaryCaptainColor,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                cardColor: cardColor,
              ),
              _buildSettingItem(
                icon: Icons.location_on,
                title: 'Location Services',
                subtitle: 'Enable or disable location tracking',
                trailing: Switch(
                  value: _locationEnabled,
                  activeColor: primaryCaptainColor,
                  onChanged: (value) {
                    setState(() => _locationEnabled = value);
                  },
                ),
                cardColor: cardColor,
              ),

              // App Settings
              _buildSectionHeader('App Settings'),
              _buildSettingItem(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Toggle dark or light theme',
                trailing: Switch(
                  value: _isDarkMode,
                  activeColor: primaryCaptainColor,
                  onChanged: (value) {
                    setState(() => _isDarkMode = value);
                    themeProvider.toggleTheme();
                  },
                ),
                cardColor: cardColor,
              ),
              _buildSettingItem(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Select your preferred language',
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
                cardColor: cardColor,
              ),

              // Support and Help
              _buildSectionHeader('Support & Help'),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help with the app',
                onTap: () {
                  // Navigate to help center
                },
                cardColor: cardColor,
              ),
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  // Show app information
                },
                cardColor: cardColor,
              ),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Terms & Privacy Policy',
                subtitle: 'View our terms and privacy policy',
                onTap: () {
                  // Navigate to terms and privacy policy
                },
                cardColor: cardColor,
              ),

              // Logout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _logout,
                ),
              ),
            ],
          ),
          bottomNavigationBar: CaptainNavBar(
            currentIndex: 3, // Adjust this based on your nav bar setup
            userId: widget.userId,
            token: widget.token,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required Color cardColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, size: 28),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
