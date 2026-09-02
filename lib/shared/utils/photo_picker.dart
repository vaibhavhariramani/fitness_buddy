import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a "Take photo" / "Choose from gallery" action sheet and returns the
/// picked image's bytes, or null if the user backed out at any point.
///
/// Centralizing this (rather than each screen calling `ImagePicker` directly
/// with a hardcoded gallery-only source) is what makes the camera option
/// available everywhere a photo can be attached — meals, weight, workouts.
Future<Uint8List?> pickPhotoFromCameraOrGallery(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
  if (file == null) return null;
  return file.readAsBytes();
}
