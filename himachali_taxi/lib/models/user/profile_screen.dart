import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:himachali_taxi/models/user/bottom_navigation_bar.dart';
import 'package:himachali_taxi/models/user/profileimagehero.dart';
import 'package:himachali_taxi/utils/supabase_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../utils/sf_manager.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _canEditImage = true;

  String? _profileImage; // Profile Picture URL
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedGender = 'Male'; // Updated variable name
  DateTime? _dateOfBirth;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _isEditing = false; // New variable for edit mode
  bool _isEmailVerified = false; // New variable for email verification status
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrlAndFetchData(); // Call helper
  }

  void _initializeBaseUrlAndFetchData() {
    try {
      _baseUrl = _getBaseUrl(); // Initialize _baseUrl
      _fetchUserData();
    } catch (e) {
      print("Error initializing profile screen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Configuration error: ${e.toString()}")),
        );
      }
    }
  }

  String _getBaseUrl() {
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      print("ERROR: BASE_URL not found in .env file.");
      throw Exception("BASE_URL not configured in .env file.");
    }
    print("ProfileScreen: Using BASE_URL: $baseUrl"); // Log the URL
    return baseUrl;
  }

  Future<void> _pickImage() async {
    if (!_canEditImage) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        if (await imageFile.exists()) {
          await _uploadImage(imageFile);
          await _fetchUserData(); // Refresh profile data
        } else {
          throw Exception('Selected image file not found');
        }
      }
    } catch (e) {
      print('Image pick error: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    final String sfUserId = await SfManager.getUserId() as String;
    final String sfToken = await SfManager.getToken() as String;

    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/upload/profile?id=$sfUserId', // Use host variable
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sfToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];

        print('Fetched user data: $userData'); // Debug print

        setState(() {
          // Map MongoDB fields to controllers
          _nameController.text = userData['firstName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _profileImage = userData['profileImage'];
          _selectedGender = userData['gender'] ?? 'Male';
          _isEmailVerified = userData['isVerified'] ?? false;

          // Parse MongoDB date
          if (userData['dateOfBirth'] != null) {
            try {
              _dateOfBirth = DateTime.parse(userData['dateOfBirth']);
            } catch (e) {
              print(
                  "Error parsing dateOfBirth: ${userData['dateOfBirth']} - $e");
              _dateOfBirth = null; // Set to null if parsing fails
            }
          } else {
            _dateOfBirth = null;
          }

          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load user data: ${jsonDecode(response.body)}',
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUserData() async {
    setState(() => _isLoading = true);
    await _fetchUserData();
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isLoading = true);

      final String? sfToken = await SfManager.getToken();
      if (sfToken == null) {
        throw Exception('Authentication token not found');
      }

      // Debug print
      final updateData = {
        'firstName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'address': _addressController.text.trim(),
      };
      print('Updating profile with data: $updateData');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/upload/update-profile'), // Use host variable
        headers: {
          'Authorization': 'Bearer $sfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      // Debug print
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Refresh profile data after successful update
          await _fetchUserData();
          setState(() => _isEditing = false);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Update error: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      final String? sfToken = await SfManager.getToken();
      if (sfToken == null) {
        throw Exception('Authentication token not found');
      }

      setState(() => _isUploading = true);

      // First upload to Supabase
      final String supabaseUrl = await SupabaseManager.uploadImage(file);
      print('Supabase URL: $supabaseUrl');

      // Then update MongoDB with the Supabase URL
      final response = await http.put(
        Uri.parse(
            '$_baseUrl/api/upload/update-profile-image'), // Use host variable
        headers: {
          'Authorization': 'Bearer $sfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'profileImageUrl': supabaseUrl,
        }),
      );

      print(
          'Profile update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() => _profileImage = supabaseUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        await _fetchUserData(); // Refresh profile data
      } else {
        throw Exception('Failed to update profile with image URL');
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ProfileImageHero(
                                  imageUrl: _profileImage,
                                  radius: 50,
                                  heroTag: 'profile-${widget.userId}',
                                  showEditButton: _isEditing,
                                  isLoading: _isUploading,
                                  onEdit: _pickImage,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _nameController.text.isEmpty
                                  ? 'User Name'
                                  : _nameController.text,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isEmailVerified
                                      ? Icons.verified_rounded
                                      : Icons.error_outline_rounded,
                                  color: _isEmailVerified
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone number field
                          _buildInfoField(
                            controller: _phoneController,
                            label: "Phone Number",
                            icon: Icons.phone,
                            enabled: _isEditing,
                          ),

                          // Gender dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: "Gender",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ))
                                .toList(),
                            onChanged: _isEditing
                                ? (value) {
                                    setState(() => _selectedGender = value!);
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Date of Birth Field
                          GestureDetector(
                            onTap: _isEditing
                                ? () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _dateOfBirth ?? DateTime(2000),
                                      firstDate: DateTime(1950),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _dateOfBirth = picked);
                                    }
                                  }
                                : null,
                            child: AbsorbPointer(
                              child: TextField(
                                controller: TextEditingController(
                                  text: _dateOfBirth != null
                                      ? "${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}"
                                      : "",
                                ),
                                enabled: _isEditing,
                                decoration: const InputDecoration(
                                  labelText: "Date of Birth",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  hintText: 'Select your date of birth',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Address Field
                          TextField(
                            controller: _addressController,
                            enabled: _isEditing,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: "Address",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'Enter your address',
                            ),
                          ),

                          if (_isEditing)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3, userId: widget.userId),
    );
  }

  Widget _buildInfoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          hintText: _isLoading ? 'Loading...' : null,
        ),
        onChanged: (value) {
          print('$label changed to: $value');
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
