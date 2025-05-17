import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routers/approutes.dart';
import '../../utils/sf_manager.dart';
import '../../utils/themes/colors.dart';
import '../../utils/themes/themeprovider.dart';
import '../auth/auth.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final String userId;
  // ignore: unused_field
  final AuthService _authService = AuthService();

  CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final primaryColor =
            themeProvider.isDarkMode ? DarkColors.primary : LightColors.primary;
        final subtextColor =
            themeProvider.isDarkMode ? DarkColors.subtext : LightColors.subtext;
        final surfaceColor =
            themeProvider.isDarkMode ? DarkColors.surface : LightColors.surface;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: subtextColor,
          backgroundColor: surfaceColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Rides',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
          onTap: (index) => _onItemTapped(context, index),
        );
      },
    );
  }

  Future<void> _onItemTapped(BuildContext context, int index) async {
    if (index == currentIndex) return;

    final String? token = await SfManager.getToken();
    if (token == null) {
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    if (!context.mounted) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
          arguments: {'userId': userId, 'token': token},
        );
        break;
      case 1:
        Navigator.pushNamed(
          context,
          AppRoutes.ride,
          arguments: {'userId': userId, 'token': token},
        );
        break;
      case 2:
        Navigator.pushNamed(
          context,
          AppRoutes.payment,
          arguments: {'userId': userId, 'token': token},
        );
        break;
      case 3:
        Navigator.pushNamed(
          context,
          AppRoutes.accounts,
          arguments: {'userId': userId, 'token': token},
        );
        break;
    }
  }
}
