import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
              border: Border.all(
                color: AppColors.imperiumGold,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildAvatarImage(),
            ),
          ),
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.imperiumGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundDark,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: size * 0.2,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.textMuted,
      );
    }

    // Check if it's a base64 data URI
    if (avatarUrl!.startsWith('data:image')) {
      try {
        final base64String = avatarUrl!.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: size * 0.5,
              color: AppColors.textMuted,
            );
          },
        );
      } catch (e) {
        return Icon(
          Icons.person,
          size: size * 0.5,
          color: AppColors.textMuted,
        );
      }
    }

    // Otherwise treat as URL
    return Image.network(
      avatarUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: size * 0.5,
          color: AppColors.textMuted,
        );
      },
    );
  }
}

/// Helper function to pick an image
Future<File?> pickImage(BuildContext context) async {
  final picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.cardDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.camera_alt, color: AppColors.imperiumGold),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: AppColors.imperiumGold),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final pickedFile = await picker.pickImage(
    source: source,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );

  if (pickedFile == null) return null;

  return File(pickedFile.path);
}
