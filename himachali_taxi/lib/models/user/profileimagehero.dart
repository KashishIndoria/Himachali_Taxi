import 'package:flutter/material.dart';

class ProfileImageHero extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String heroTag;
  final VoidCallback? onTap;
  final bool showEditButton;
  final bool isLoading;
  final VoidCallback? onEdit;

  const ProfileImageHero({
    super.key,
    this.imageUrl,
    required this.radius,
    required this.heroTag,
    this.onTap,
    this.showEditButton = false,
    this.isLoading = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    bool hasValidImage = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: hasValidImage
                      ? NetworkImage(imageUrl!)
                      : const AssetImage('assets/images/profile_avatar.png')
                          as ImageProvider,
                  child: !hasValidImage
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (showEditButton && onEdit != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: isLoading ? null : onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: onEdit,
                              tooltip: 'Change Profile Picture',
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
