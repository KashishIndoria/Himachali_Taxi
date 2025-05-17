import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routers/approutes.dart';
import 'utils/themes/themeprovider.dart';
import 'utils/themes/colors.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor =
        themeProvider.isDarkMode ? DarkColors.text : LightColors.text;
    final primaryColor =
        themeProvider.isDarkMode ? DarkColors.primary : LightColors.primary;
    final onPrimaryColor =
        themeProvider.isDarkMode ? DarkColors.onPrimary : LightColors.onPrimary;
    final onPrimaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.onPrimaryCaptain
        : LightColors.onPrimaryCaptain;
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              child: Image.asset(
                "assets/images/taxilogo.png",
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 20),
            Text(
              "Himachali Taxi",
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 100),
            Image.asset(
              "assets/images/taxi.png",
              height: 100,
              width: 100,
            ),
            Text(
              "Welcome to Himachali Taxi",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 30),
            Image.asset(
              "assets/images/map.png",
              height: 200,
              width: 200,
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: primaryColor,
                    foregroundColor: onPrimaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: onPrimaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Login as User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.captainLogin);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: primaryCaptainColor,
                    foregroundColor: onPrimaryCaptainColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drive_eta, color: onPrimaryCaptainColor),
                      SizedBox(width: 8),
                      Text(
                        "Login as Captain",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryCaptainColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
