import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/themes/themeprovider.dart';
import '../../utils/themes/colors.dart';
import 'bottom_navigation_bar.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final primaryColor =
            themeProvider.isDarkMode ? DarkColors.primary : LightColors.primary;
        final onPrimaryColor = themeProvider.isDarkMode
            ? DarkColors.onPrimary
            : LightColors.onPrimary;
        final dividerColor =
            themeProvider.isDarkMode ? DarkColors.divider : LightColors.divider;
        final textColor =
            themeProvider.isDarkMode ? DarkColors.text : LightColors.text;
        final subtextColor =
            themeProvider.isDarkMode ? DarkColors.subtext : LightColors.subtext;

        return Scaffold(
          appBar: AppBar(
            title: Text('Settings', style: TextStyle(color: onPrimaryColor)),
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: onPrimaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: Text('Push Notifications',
                    style: TextStyle(color: textColor)),
                subtitle: Text('Enable push notifications',
                    style: TextStyle(color: subtextColor)),
                secondary: Icon(Icons.notifications, color: primaryColor),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: Icon(Icons.language, color: primaryColor),
                title: Text('Language', style: TextStyle(color: textColor)),
                subtitle:
                    Text('English', style: TextStyle(color: subtextColor)),
                trailing: Icon(Icons.arrow_forward_ios, color: subtextColor),
                onTap: () {},
              ),
              Divider(color: dividerColor),
              SwitchListTile(
                title: Text('Dark Mode', style: TextStyle(color: textColor)),
                subtitle: Text('Enable dark theme',
                    style: TextStyle(color: subtextColor)),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: primaryColor,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: primaryColor),
                title: Text('Privacy Settings',
                    style: TextStyle(color: textColor)),
                trailing: Icon(Icons.arrow_forward_ios, color: subtextColor),
                onTap: () {},
              ),
            ],
          ),
          bottomNavigationBar: CustomNavBar(
            currentIndex: 3,
            userId: widget.userId,
          ),
        );
      },
    );
  }
}
