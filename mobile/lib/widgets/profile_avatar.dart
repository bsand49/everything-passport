import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final File? selectedImage;
  final double radius;
  final VoidCallback? onEditPressed;
  final IconData fallbackIcon;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.selectedImage,
    this.radius = 60,
    this.onEditPressed,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;

    if (selectedImage != null) {
      backgroundImage = FileImage(selectedImage!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(
        photoUrl!,
        maxWidth: (radius * 4).toInt(),
        maxHeight: (radius * 4).toInt(),
      );
    }

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? Icon(fallbackIcon, size: radius, color: Colors.grey)
          : null,
    );

    if (onEditPressed == null) {
      return avatar;
    }

    return Center(
      child: Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                onPressed: onEditPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
