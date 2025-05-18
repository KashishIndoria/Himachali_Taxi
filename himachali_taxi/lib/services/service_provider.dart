import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'ride_service.dart';
import 'socket_service.dart';

class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  factory ServiceProvider() => _instance;

  late final Dio _dio;
  late final SocketService _socketService;
  late final RideService _rideService;

  ServiceProvider._internal() {
    // Initialize Dio with base configuration
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('BASE_URL',
          defaultValue:
              'http://localhost:3000'), // Get from environment or use default
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final token = _getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    // Initialize Socket Service
    _socketService = SocketService();

    // Initialize Ride Service
    _rideService = RideService(_dio, _socketService);
  }

  // Getters for services
  RideService get rideService => _rideService;
  SocketService get socketService => _socketService;
  Dio get dio => _dio;

  // Helper method to get auth token
  String? _getAuthToken() {
    // Implement your token storage/retrieval logic here
    // For example, using shared preferences or secure storage
    return null;
  }

  // Method to update base URL (useful for different environments)
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // Method to update auth token
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Cleanup method
  void dispose() {
    _socketService.dispose();
    _rideService.dispose();
  }
}
