import 'package:flutter/material.dart';
import 'package:himachali_taxi/provider/captain_provider.dart';
import 'package:himachali_taxi/provider/socket_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'routers/approutes.dart';
import 'utils/themes/themeprovider.dart';
import 'utils/sf_manager.dart'; // Add this import for SfManager
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Load environment variables from .env file
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Added comma
        ChangeNotifierProvider(
            create: (_) => SocketProvider()), // Add SocketProvider here
        ChangeNotifierProvider(
            create: (_) => CaptainProvider()), // Add CaptainProvider
      ],
      child: const MyApp(),
    ),
  );
}

// Add AuthProvider class for authentication management
class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userRole;
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  bool get isLoggedIn => _token != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _token = await SfManager.getToken();
    _userId = await SfManager.getUserId();
    _userRole = await SfManager.getUserRole();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(
      BuildContext context, String token, String userId, String role) async {
    await SfManager.setToken(token);
    await SfManager.setUserId(userId);
    await SfManager.setUserRole(role);
    _token = token;
    _userId = userId;
    _userRole = role;
    notifyListeners();

    try {
      // Use context to get SocketProvider
      Provider.of<SocketProvider>(context, listen: false)
          .connect(token, userId, role);
    } catch (e) {
      print("Error connecting socket after login: $e");
      // Handle error appropriately, maybe show a message to the user
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      Provider.of<SocketProvider>(context, listen: false).disconnect();
    } catch (e) {
      print("Error disconnecting socket during logout: $e");
    }
    await SfManager.clearToken();
    await SfManager.clearUserId();
    await SfManager.clearUserRole();
    _token = null;
    _userId = null;
    _userRole = null;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onGenerateInitialRoutes: (initialRouteName) {
            // Parameter renamed for clarity
            return [
              AppRoutes.onGenerateRoute(
                RouteSettings(name: initialRouteName), // Use the parameter
              )!,
            ];
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Error'),
                ),
                body: Center(
                  child: Text(
                    'Route not found: ${settings.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
