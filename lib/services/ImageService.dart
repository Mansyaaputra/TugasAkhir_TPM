import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pilih foto dari galeri
  static Future<String?> pickImageFromGallery() async {
    try {
      // Request permission for gallery access
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        var permission = await Permission.photos.request();
        if (!permission.isGranted) {
          // Fallback untuk Android < 13
          permission = await Permission.storage.request();
          if (!permission.isGranted) {
            print('Gallery permission not granted');
            return null;
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Convert to base64 for storage
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Ambil foto dengan kamera
  static Future<String?> takePicture() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          print('Camera permission not granted');
          return null;
        }
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      }
      return null;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  /// Tampilkan dialog pilihan sumber foto
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.camera_enhance, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Pilih Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(
                icon: Icons.camera_alt,
                title: 'Ambil Foto',
                subtitle: 'Gunakan kamera perangkat',
                onTap: () async {
                  final imageUrl = await takePicture();
                  if (imageUrl != null) {
                    Navigator.pop(context, imageUrl);
                  }
                },
              ),
              Divider(height: 1),
              _buildOptionTile(
                icon: Icons.photo_library,
                title: 'Pilih dari Galeri',
                subtitle: 'Pilih foto yang sudah ada',
                onTap: () async {
                  final imageUrl = await pickImageFromGallery();
                  if (imageUrl != null) {
                    Navigator.pop(context, imageUrl);
                  }
                },
              ),
              Divider(height: 1),
              _buildOptionTile(
                icon: Icons.person,
                title: 'Avatar Default',
                subtitle: 'Gunakan avatar otomatis',
                onTap: () {
                  Navigator.pop(context, 'default');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue.shade600, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate avatar default berdasarkan username
  static String getDefaultAvatar(String username) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final colors = [
      'FF6B6B',
      '4ECDC4',
      'FFD93D',
      '6BCF7F',
      'FF8E53',
      'A8E6CF',
      'FF7F7F',
      '87CEEB',
      'DDA0DD',
      'F0E68C'
    ];
    final colorIndex = username.hashCode % colors.length;
    return 'https://ui-avatars.com/api/?name=$initial&background=${colors[colorIndex]}&color=ffffff&size=128';
  }
}
