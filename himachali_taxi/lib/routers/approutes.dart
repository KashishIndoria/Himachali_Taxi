import 'package:flutter/material.dart';
import 'package:himachali_taxi/models/auth/captain.login.dart';
import 'package:himachali_taxi/models/auth/captain.signup.dart';
import 'package:himachali_taxi/models/captain/captainHome.dart';
import 'package:himachali_taxi/models/captain/captainSetting.dart';
import 'package:himachali_taxi/models/captain/captain_account_screen.dart';
import 'package:himachali_taxi/models/captain/captain_profile_screen.dart';
import 'package:himachali_taxi/models/captain/earning_screen.dart';
import 'package:provider/provider.dart';
import 'package:himachali_taxi/models/user/aboutus_screen.dart';
import 'package:himachali_taxi/models/user/acounts_screen.dart';
import 'package:himachali_taxi/models/user/paymentscreen.dart';
import 'package:himachali_taxi/models/user/ridehistory.dart';
import 'package:himachali_taxi/models/user/service_screen.dart';
import 'package:himachali_taxi/models/user/settings_screen.dart';
import '../models/auth/login.dart';
import '../models/auth/signup.dart';
import '../models/auth/otp_verification_screen.dart';
import '../models/user/home_screen.dart';
import '../splash_screen.dart';
import '../models/auth/auth.dart';
import '../utils/sf_manager.dart'; // Add import for top-level auth functions

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String verifyOtp = '/verify-otp';
  static const String map = '/map';
  static const String service = '/service';
  static const String accounts = '/accounts';
  static const String settings = '/settings';
  static const String aboutus = '/aboutus';
  static const String captainLogin = '/captain-login';
  static const String captainSignup = '/captain-signup';
  static const String captainHome = '/captain_home';
  static const String ride = '/ride-history';
  static const String payment = '/payment';
  static const String captainHomeScreen = '/captain-home-screen';
  static const String captainRides = '/captain_rides';
  static const String captainEarnings = '/captain_earnings';
  static const String captainProfile = '/captain_profile';
  static const String captainAccount = '/captain_account';
  static const String captainSettings = '/captain_settings';

  // Static routes
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => SplashScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
    };
  }

  // Get authentication state including userId and token
  static Future<Map<String, dynamic>> _getAuthState() async {
    final authService = AuthService();
    final token = await authService.getToken();
    final userId = await authService.getUserId();
    final role = await authService.getUserRole();
    final isAuthenticated = await authService.isAuthenticated();

    return {
      'isAuthenticated': isAuthenticated,
      'role': role,
      'userId': userId,
      'token': token,
    };
  }

  // Dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        // Check authentication for protected routes
        if (_isProtectedRoute(settings.name!)) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getAuthState(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Not authenticated
              if (snapshot.data?['isAuthenticated'] != true) {
                return settings.name == captainLogin
                    ? const CaptainLoginScreen()
                    : const LoginScreen();
              }

              // Check if this is a captain route but user is not a captain
              final userRole = snapshot.data?['role'] ?? 'user';
              if (_isCaptainRoute(settings.name!) && userRole != 'captain') {
                // Redirect to user home
                return HomeScreen(
                  userId: snapshot.data?['userId'] ?? '',
                  token: snapshot.data?['token'] ?? '',
                );
              }

              // Check if this is a user route but user is a captain
              if (_isUserRoute(settings.name!) && userRole == 'captain') {
                // Redirect to captain home
                return CaptainHomeScreen(
                  userId: snapshot.data?['userId'] ?? '',
                  token: snapshot.data?['token'] ?? '',
                );
              }

              // Continue with protected route
              return _buildRoute(settings);
            },
          );
        }

        // Public routes
        return _buildRoute(settings);
      },
    );
  }

  static bool _isProtectedRoute(String routeName) {
    return routeName != login &&
        routeName != signup &&
        routeName != splash &&
        routeName != captainLogin &&
        routeName != captainSignup &&
        routeName != verifyOtp;
  }

  // Determine if a user with the given role can access the route
  static bool _hasRoleAccess(String routeName, String userRole) {
    if (_isCaptainRoute(routeName) && userRole != 'captain') {
      return false;
    }

    if (_isUserRoute(routeName) && userRole != 'user') {
      return false;
    }

    return true;
  }

  // Check if route is captain-specific
  static bool _isCaptainRoute(String routeName) {
    return routeName == captainHome ||
        routeName == captainHomeScreen ||
        routeName == captainRides ||
        routeName == captainEarnings ||
        routeName == captainProfile ||
        routeName == captainAccount;
  }

  // Check if route is user-specific
  static bool _isUserRoute(String routeName) {
    return routeName == home ||
        routeName == accounts ||
        routeName == settings ||
        routeName == aboutus ||
        routeName == ride ||
        routeName == payment ||
        routeName == service;
  }

  static Widget _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String? ?? '';
        final token = args?['token'] as String? ?? '';

        if (userId.isEmpty || token.isEmpty) {
          return const LoginScreen();
        }

        return HomeScreen(
          userId: userId,
          token: token,
        );

      case accounts:
        final args = settings.arguments as Map<String, dynamic>?;
        return AccountsScreen(
          userId: args?['userId'] ?? '',
        );
      case AppRoutes.settings:
        final args = settings.arguments as Map<String, dynamic>?;
        return SettingsScreen(
          userId: args?['userId'] ?? '',
        );

      case aboutus:
        final args = settings.arguments as Map<String, dynamic>?;
        return AboutUsScreen(
          userId: args?['userId'] ?? '',
        );

      case captainHome:
        final args = settings.arguments as Map<String, dynamic>?;
        return CaptainHomeScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case captainSettings:
        final args = settings.arguments as Map<String, dynamic>?;
        return CaptainSettingsScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );
      case captainEarnings:
        final args = settings.arguments as Map<String, dynamic>?;
        return CaptainEarningsScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case captainProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return CaptainProfileScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case captainAccount:
        final args = settings.arguments as Map<String, dynamic>?;
        return CaptainAccountScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case verifyOtp:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid navigation arguments')),
          );
        }
        return OTPVerificationScreen(
          email: args['email'] ?? '',
          role: args['role'] ?? 'user',
          userData: args['userData'] ?? {},
        );

      case captainLogin:
        return const CaptainLoginScreen();

      case captainSignup:
        return const CaptainSignupScreen();

      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        return PaymentScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case ride:
        final args = settings.arguments as Map<String, dynamic>?;
        return RidesHistoryScreen(
          userId: args?['userId'] ?? '',
          token: args?['token'] ?? '',
        );

      case service:
        final args = settings.arguments as Map<String, dynamic>?;
        return ServicesScreen(
          userId: args?['userId'] ?? '',
        );

      case login:
        return const LoginScreen();

      case signup:
        return const SignupScreen();

      case splash:
        return SplashScreen();

      default:
        // Handle unknown routes
        return Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        );
    }
  }
}
