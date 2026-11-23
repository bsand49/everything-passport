import 'dart:io';

import 'package:material_ui/material_ui.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
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
      backgroundColor: colorScheme.surfaceContainerHighest,
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? Icon(fallbackIcon, size: radius, color: colorScheme.outline)
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
              backgroundColor: colorScheme.primary,
              radius: 20,
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
                onPressed: onEditPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
