import 'package:flutter/material.dart';
import 'package:himachali_taxi/routers/approutes.dart';
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:provider/provider.dart';

class CaptainNavBar extends StatelessWidget {
  final int currentIndex;
  final String userId;
  final String token;

  const CaptainNavBar({
    Key? key,
    required this.currentIndex,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: primaryCaptainColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _navigateToTab(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Rides',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payments),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    if (index == currentIndex) return; // Already on this tab

    switch (index) {
      case 0:
        if (currentIndex != 0) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.captainHome,
            arguments: {'userId': userId, 'token': token},
          );
        }
        break;
      case 1:
        Navigator.pushNamed(
          context,
          AppRoutes.captainRides,
          arguments: {'userId': userId, 'token': token},
        );
        break;
      case 2:
        Navigator.pushNamed(
          context,
          AppRoutes.captainEarnings,
          arguments: {'userId': userId, 'token': token},
        );
        break;
      case 3:
        Navigator.pushNamed(
          context,
          AppRoutes.captainSettings,
          arguments: {'userId': userId, 'token': token},
        );
        break;
    }
  }
}
