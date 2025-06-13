import 'package:flutter/material.dart';
import '../models/UserModel.dart';
import '../services/AuthService.dart';
import '../services/NotificationService.dart';
import '../services/ImageService.dart';
import 'dart:convert';

class EditUserPage extends StatefulWidget {
  final User user;

  const EditUserPage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController();
    _avatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newUsername = _usernameController.text.trim();
      bool success;

      if (_passwordController.text.isNotEmpty) {
        // Update with new password
        success = await AuthService().updateUser(
          widget.user.username,
          newUsername,
          _passwordController.text,
          avatarUrl: _avatarUrl,
        );
      } else {
        // Keep existing password - only update username and avatar
        success = await AuthService().updateUserWithoutPassword(
          widget.user.username,
          newUsername,
          avatarUrl: _avatarUrl,
        );
      }

      if (success) {
        // Create updated user object
        User updatedUser = User(
          username: newUsername,
          passwordHash: _passwordController.text.isNotEmpty
              ? null // Will be set by AuthService
              : widget.user.passwordHash,
          avatarUrl: _avatarUrl,
        );

        NotificationService.showSuccess(
          'Profil Diperbarui',
          'Profil $newUsername berhasil diperbarui!',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedUser);
        }
      } else {
        NotificationService.showError(
          'Update Gagal',
          'Gagal memperbarui profil. Username mungkin sudah digunakan.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Gagal memperbarui profil. Username mungkin sudah digunakan.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      NotificationService.showError(
        'Error Update',
        'Terjadi kesalahan: ${e.toString()}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final imageUrl = await ImageService.showImageSourceDialog(context);

      if (imageUrl != null) {
        String finalImageUrl = imageUrl;

        // Jika pilih default, generate avatar berdasarkan username
        if (imageUrl == 'default') {
          finalImageUrl =
              ImageService.getDefaultAvatar(_usernameController.text);
        }

        setState(() {
          _avatarUrl = finalImageUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildProfileImageEdit() {
    String imageUrl =
        _avatarUrl ?? ImageService.getDefaultAvatar(_usernameController.text);

    return GestureDetector(
      onTap: _changeProfilePicture,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: ClipOval(
          child: _buildImage(imageUrl),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Jika base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      } catch (e) {
        return _buildDefaultIcon();
      }
    }

    // Jika URL image
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
      errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Avatar
              Center(
                child: Column(
                  children: [
                    _buildProfileImageEdit(),
                    SizedBox(height: 16),
                    Text(
                      'Tap untuk mengubah foto profil',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height:
                      20), // Grid Avatar Options (Hidden - akan menggunakan ImageService)
              SizedBox(height: 20),
              SizedBox(height: 32),

              // Form Fields
              Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru (Opsional)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  helperText: 'Kosongkan jika tidak ingin mengubah password',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateUser,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
