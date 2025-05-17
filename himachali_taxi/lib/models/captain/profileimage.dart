import 'package:flutter/material.dart';
import 'package:himachali_taxi/utils/supabase_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileImage extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final String heroTag;
  final bool showEditButton;
  final bool isLoading;
  final Function(String) onImageUpdated;

  const ProfileImage({
    Key? key,
    required this.imageUrl,
    required this.radius,
    required this.heroTag,
    this.showEditButton = false,
    this.isLoading = false,
    required this.onImageUpdated,
  }) : super(key: key);

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  bool _localIsLoading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _localIsLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Upload to Supabase
        final String supabaseUrl =
            await SupabaseManager.uploadImage(File(pickedFile.path));

        // Call the parent callback with the new URL
        widget.onImageUpdated(supabaseUrl);
      }
    } catch (e) {
      print('Image upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _localIsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: widget.heroTag,
          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? NetworkImage(widget.imageUrl!)
                    : null,
            child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                ? Icon(
                    Icons.person,
                    size: widget.radius,
                    color: Colors.grey[400],
                  )
                : null,
          ),
        ),
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _localIsLoading || widget.isLoading
                  ? null
                  : _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _localIsLoading || widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt,
                        size: 24,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
