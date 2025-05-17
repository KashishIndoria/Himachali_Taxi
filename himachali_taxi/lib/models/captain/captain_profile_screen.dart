import 'dart:convert';
import 'dart:io' show File, Platform; // Import Platform
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:himachali_taxi/models/captain/captainNavBAr.dart';
import 'package:himachali_taxi/models/user/profileimagehero.dart';
import 'package:himachali_taxi/services/api_service.dart';
import 'package:himachali_taxi/utils/supabase_manager.dart';
import 'package:himachali_taxi/utils/themes/colors.dart';
import 'package:himachali_taxi/utils/themes/themeprovider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../../utils/sf_manager.dart';

class CaptainProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  const CaptainProfileScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _CaptainProfileScreenState createState() => _CaptainProfileScreenState();
}

class _CaptainProfileScreenState extends State<CaptainProfileScreen>
    with SingleTickerProviderStateMixin {
  // Form Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Vehicle Controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleLicensePlateController =
      TextEditingController();

  // License Controllers
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseStateController = TextEditingController();

  // State variables
  String? _profileImage;
  DateTime? _licenseExpiry;
  bool _isEmailVerified = false;
  bool _isLicenseVerified = false;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isEditing = false;

  // Statistics
  double _averageRating = 0.0;
  int _totalRatings = 0;
  int _totalRides = 0;
  double _totalEarnings = 0.0;
  String _accountStatus = 'pending';

  // Tab controller for profile sections
  late TabController _tabController;

  late final String _baseUrl; // Use baseUrl from .env
  Future<Map<String, dynamic>?>? _reviewsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeBaseUrlAndFetchData();
    _fetchReviews();
  }

  // Helper to initialize base URL and fetch data
  void _initializeBaseUrlAndFetchData() {
    try {
      _baseUrl = _getBaseUrl();
      _fetchCaptainData();
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

  // Helper to get Base URL from .env
  String _getBaseUrl() {
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      print("ERROR: BASE_URL not found in .env file.");
      throw Exception("BASE_URL not configured in .env file.");
    }
    return baseUrl;
  }

  Future<void> _fetchCaptainData() async {
    // Ensure baseUrl is initialized
    if (_baseUrl.isEmpty) {
      print("Base URL not initialized. Cannot fetch data.");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Configuration error: Base URL missing.")),
        );
      }
      return;
    }

    if (!mounted) return; // Check if mounted before starting async operation
    setState(() => _isLoading = true);

    try {
      final captainToken = await SfManager.getToken();
      if (captainToken == null) {
        throw Exception("Authentication token not found.");
      }

      print('Captain token: $captainToken');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/captain/profile/${widget.userId}'), // Use _baseUrl
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $captainToken',
        },
      );

      if (!mounted) return; // Check again after await

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        setState(() {
          // Handle profile image correctly
          if (data['profileImage'] != null &&
              data['profileImage'].toString().isNotEmpty) {
            String imageUrl = data['profileImage'].toString();

            // Make sure URL has a proper scheme
            if (imageUrl.startsWith('file://')) {
              // Skip file:// URLs if they don't have a proper path
              if (imageUrl == 'file:///' || imageUrl == 'file://') {
                _profileImage = null;
              } else {
                _profileImage = imageUrl;
              }
            } else if (!imageUrl.startsWith('http://') &&
                !imageUrl.startsWith('https://')) {
              // If URL doesn't have a scheme, add https://
              _profileImage = 'https://$imageUrl';
            } else {
              // URL already has proper scheme
              _profileImage = imageUrl;
            }

            print('Profile image URL: $_profileImage'); // For debugging
          } else {
            _profileImage = null;
          }
          // Personal info
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isEmailVerified = data['isVerified'] ?? false;

          // Vehicle info
          final vehicleDetails = data['vehicleDetails'] ?? {};
          _vehicleMakeController.text = vehicleDetails['make'] ?? '';
          _vehicleModelController.text = vehicleDetails['model'] ?? '';
          _vehicleYearController.text =
              vehicleDetails['year']?.toString() ?? '';
          _vehicleColorController.text = vehicleDetails['color'] ?? '';
          _vehicleLicensePlateController.text =
              vehicleDetails['licensePlate'] ?? '';

          // License info
          final licenseDetails = data['drivingLicense'] ?? {};
          _licenseNumberController.text = licenseDetails['number'] ?? '';
          _licenseStateController.text = licenseDetails['state'] ?? '';
          _isLicenseVerified = licenseDetails['verified'] ?? false;

          if (licenseDetails['expiry'] != null) {
            _licenseExpiry = DateTime.parse(licenseDetails['expiry']);
          }

          // Statistics
          _averageRating = (data['averageRating'] ?? data['rating'] ?? 0.0)
              .toDouble(); // Use averageRating or fallback to rating
          _totalRatings =
              (data['totalRatings'] ?? data['totalRides'] ?? 0).toInt();
          _totalRides = data['totalRides'] ?? 0;
          _totalEarnings = (data['totalEarnings'] ?? 0.0).toDouble();
          _accountStatus = data['accountStatus'] ?? 'pending';

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load captain data: ${response.body}');
      }
    } catch (e) {
      print('Error fetching captain data: $e');
      if (mounted) {
        // Add mounted check here
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch profile data: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Personal info update
      final personalData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Vehicle details update
      final vehicleData = {
        'vehicleDetails': {
          'make': _vehicleMakeController.text.trim(),
          'model': _vehicleModelController.text.trim(),
          'year': int.tryParse(_vehicleYearController.text.trim()) ?? 0,
          'color': _vehicleColorController.text.trim(),
          'licensePlate': _vehicleLicensePlateController.text.trim(),
        }
      };

      // License details update
      final licenseData = {
        'drivingLicense': {
          'number': _licenseNumberController.text.trim(),
          'state': _licenseStateController.text.trim(),
          'expiry': _licenseExpiry?.toIso8601String(),
        }
      };

      // Combine all updates
      final updateData = {
        ...personalData,
        ...vehicleData,
        ...licenseData,
      };

      final captainToken = await SfManager.getToken(); // Get token for saving
      if (captainToken == null) {
        throw Exception("Authentication token not found for saving.");
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/captain/profile'), // Use _baseUrl
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $captainToken', // Use fetched token
        },
        body: jsonEncode(updateData),
      );

      if (!mounted) return; // Check after await

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        _fetchCaptainData(); // Refresh data
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Update error: $e');
      if (mounted) {
        // Add mounted check here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update profile: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Add mounted check here
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() => _isUploading = true);

        // Upload to Supabase
        final String supabaseUrl =
            await SupabaseManager.uploadImage(File(pickedFile.path));

        print('Supabase URL before update: $supabaseUrl'); // For debugging

        final captainToken =
            await SfManager.getToken(); // Get token for image update
        if (captainToken == null) {
          throw Exception("Authentication token not found for image update.");
        }

        // Update profile image in MongoDB
        final response = await http.put(
          Uri.parse(
              '$_baseUrl/api/captain/update-profile-image'), // Use _baseUrl
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $captainToken', // Use fetched token
          },
          body: jsonEncode({'profileImageUrl': supabaseUrl}),
        );

        if (!mounted) return; // Check after await

        if (response.statusCode == 200) {
          if (supabaseUrl.startsWith('http://') ||
              supabaseUrl.startsWith('https://')) {
            setState(() => _profileImage = supabaseUrl);
            print(
                'profile image updated successfuly :$_profileImage'); // For debugging
          } else {
            print('Warning : Invalid URL format: $supabaseUrl');
          }

          await _fetchCaptainData(); // Refresh data
        } else {
          print(
              'Failed to update profile image. Status: ${response.statusCode}, Body: ${response.body}');
          throw Exception('Failed to update profile image: ${response.body}');
        }
      }
    } catch (e) {
      print('Image upload error: $e');
      if (mounted) {
        // Add mounted check here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to upload image: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        // Add mounted check here
        setState(() => _isUploading = false);
      }
    }
  }

  void _fetchReviews() {
    if (!mounted) return;
    setState(() {
      _reviewsFuture = _apiService.getDriverRatings(widget.userId);
    });
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
        final textColor =
            themeProvider.isDarkMode ? DarkColors.text : LightColors.text;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            elevation: 0,
            title: Text(
              'Captain Profile',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: primaryCaptainColor,
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Vehicle'),
                Tab(text: 'License'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: primaryCaptainColor))
                  : _buildProfileTab(themeProvider),
              _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: primaryCaptainColor))
                  : _buildVehicleTab(themeProvider),
              _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: primaryCaptainColor))
                  : _buildLicenseTab(themeProvider),
            ],
          ),
          bottomNavigationBar: CaptainNavBar(
            currentIndex: 3,
            userId: widget.userId,
            token: widget.token,
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(ThemeProvider themeProvider) {
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;
    final cardColor =
        themeProvider.isDarkMode ? DarkColors.surface : LightColors.surface;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with profile image
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            decoration: BoxDecoration(
              color: primaryCaptainColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  ProfileImageHero(
                    imageUrl: _profileImage,
                    radius: 60,
                    heroTag: 'captain-${widget.userId}',
                    showEditButton: _isEditing,
                    isLoading: _isUploading,
                    onEdit: _pickImage,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${_firstNameController.text} ${_lastNameController.text}",
                    style: const TextStyle(
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

          // Captain Statistics
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Captain Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Rating Section
                        Column(
                          children: [
                            RatingBarIndicator(
                              rating: _averageRating,
                              itemBuilder: (context, index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 25.0, // Adjust size as needed
                              direction: Axis.horizontal,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_averageRating.toStringAsFixed(1)} ($_totalRatings ratings)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        // Earnings Section
                        _buildStatItem(
                          icon: Icons.currency_rupee,
                          value: _totalEarnings.toStringAsFixed(0),
                          label: 'Earnings',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Account Status: '),
                        Chip(
                          label: Text(_accountStatus),
                          backgroundColor: _getStatusColor(_accountStatus),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Reviews Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _reviewsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(15.0),
                              child: CircularProgressIndicator()));
                    } else if (snapshot.hasError) {
                      return Center(
                          child:
                              Text('Error loading reviews: ${snapshot.error}'));
                    } else if (!snapshot.hasData ||
                        snapshot.data == null ||
                        (snapshot.data!['ratings'] as List?)?.isEmpty == true) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Text('No reviews yet.')));
                    }

                    final List<dynamic> reviewsList =
                        snapshot.data!['ratings'] ?? [];

                    return ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Important inside SingleChildScrollView
                      itemCount: reviewsList.length,
                      itemBuilder: (context, index) {
                        final review =
                            reviewsList[index] as Map<String, dynamic>? ?? {};
                        final user = review['user'] as Map<String, dynamic>?;
                        final comment = review['comment'] as String?;
                        final ratingValue =
                            (review['rating'] as num?)?.toDouble() ?? 0.0;
                        final userName =
                            user?['name'] as String? ?? 'Anonymous User';
                        // Optional: Format timestamp
                        // final timestamp = review['timestamp'] as String?;
                        // final formattedDate = timestamp != null ? intl.DateFormat('MMM d, yyyy').format(DateTime.parse(timestamp)) : '';

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          elevation: 1,
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                    child: Text(userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500))),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingBarIndicator(
                                  rating: ratingValue,
                                  itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 16.0,
                                ),
                                if (comment != null && comment.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(comment),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20), // Add some space at the bottom
              ],
            ),
          ),
          // Personal Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person,
                  enabled: _isEditing,
                ),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person,
                  enabled: _isEditing,
                ),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  enabled: false, // Email can't be edited
                  suffix: Icon(
                    _isEmailVerified ? Icons.verified : Icons.info_outline,
                    color: _isEmailVerified ? Colors.green : Colors.orange,
                  ),
                ),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone,
                  enabled: _isEditing,
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
                          backgroundColor: primaryCaptainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
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
    );
  }

  Widget _buildVehicleTab(ThemeProvider themeProvider) {
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Make
          _buildTextField(
            controller: _vehicleMakeController,
            label: 'Make',
            icon: Icons.directions_car,
            enabled: _isEditing,
          ),

          // Vehicle Model
          _buildTextField(
            controller: _vehicleModelController,
            label: 'Model',
            icon: Icons.directions_car_filled,
            enabled: _isEditing,
          ),

          // Vehicle Year
          _buildTextField(
            controller: _vehicleYearController,
            label: 'Year',
            icon: Icons.date_range,
            enabled: _isEditing,
            keyboardType: TextInputType.number,
          ),

          // Vehicle Color
          _buildTextField(
            controller: _vehicleColorController,
            label: 'Color',
            icon: Icons.color_lens,
            enabled: _isEditing,
          ),

          // License Plate
          _buildTextField(
            controller: _vehicleLicensePlateController,
            label: 'License Plate',
            icon: Icons.badge,
            enabled: _isEditing,
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
                    backgroundColor: primaryCaptainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Vehicle Information',
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
    );
  }

  Widget _buildLicenseTab(ThemeProvider themeProvider) {
    final primaryCaptainColor = themeProvider.isDarkMode
        ? DarkColors.primaryCaptain
        : LightColors.primaryCaptain;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'License Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(_isLicenseVerified ? 'Verified' : 'Pending'),
                backgroundColor: _isLicenseVerified
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                labelStyle: TextStyle(
                  color: _isLicenseVerified
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // License Number
          _buildTextField(
            controller: _licenseNumberController,
            label: 'License Number',
            icon: Icons.credit_card,
            enabled: _isEditing,
          ),

          // License State
          _buildTextField(
            controller: _licenseStateController,
            label: 'State',
            icon: Icons.location_on,
            enabled: _isEditing,
          ),

          // License Expiry
          GestureDetector(
            onTap: _isEditing
                ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _licenseExpiry ??
                          DateTime.now().add(Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365 * 10)),
                    );
                    if (picked != null) {
                      setState(() => _licenseExpiry = picked);
                    }
                  }
                : null,
            child: AbsorbPointer(
              child: _buildTextField(
                controller: TextEditingController(
                  text: _licenseExpiry != null
                      ? intl.DateFormat('dd/MM/yyyy').format(_licenseExpiry!)
                      : '',
                ),
                label: 'Expiry Date',
                icon: Icons.calendar_today,
                enabled: _isEditing,
                hintText: 'Select expiry date',
              ),
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
                    backgroundColor: primaryCaptainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save License Information',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    Widget? suffix,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'suspended':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _vehicleLicensePlateController.dispose();
    _licenseNumberController.dispose();
    _licenseStateController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
