import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:himachali_taxi/main.dart';
import 'package:himachali_taxi/models/auth/auth.dart'; // Assuming AuthProvider is defined here or imported via main.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../routers/approutes.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key});

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Use late final for clarity on initialization
  late final String _backendUrl;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure .env file exists in himachali_taxi/ with BACKEND_URL or BASE_URL
    final url = dotenv.env['BACKEND_URL'] ?? dotenv.env['BASE_URL'];
    if (url == null) {
      // Throw an error as the app likely needs a backend URL to function.
      // Alternatively, provide a hardcoded default URL: _backendUrl = 'http://default.url';
      throw Exception(
          'Backend URL not configured. Please set BACKEND_URL or BASE_URL in your .env file.');
    }
    _backendUrl = url; // url is now guaranteed non-null
    print("Backend URL configured: $_backendUrl"); // Log the URL being used
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Captain Login'),
          backgroundColor: Colors.amber,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/captain.png',
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    // Basic email format check
                    if (!RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black87),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.captainSignup);
                  },
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard if it's open
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String apiUrl = '$_backendUrl/api/auth/captain/login';
    print(
        "Attempting to login captain at: $apiUrl"); // Log the specific endpoint being called

    try {
      // Make API request to login endpoint
      final response = await http.post(
        Uri.parse(apiUrl), // Use the constructed apiUrl
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return; // Check if the widget is still in the tree

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'] as String?;
        final captainData = responseData['captain'];

        if (captainData == null || token == null) {
          throw Exception(
              'Invalid server response: missing token or captain data');
        }

        final userId = captainData['_id'] as String?;
        if (userId == null) {
          throw Exception('Invalid server response: missing captain ID');
        }

        // Use AuthProvider to handle login state and persistence
        await Provider.of<AuthProvider>(context, listen: false)
            .login(context, token, userId, 'captain');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to captain home after a short delay to show snackbar
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.captainHome,
            (route) => false,
            arguments: {
              'userId': userId,
              'token': token,
            },
          );
        }
      } else {
        // Handle login failure using message from backend
        throw Exception(responseData['message'] ??
            'Login failed with status code ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      print("Captain login failed in UI: $e"); // Log the full error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Display a user-friendly error message
          content: Text(
              "Login failed: ${e.toString().replaceFirst("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
