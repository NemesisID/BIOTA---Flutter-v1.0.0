import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:biota_2/widgets/image_crop_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImageFile;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _fullNameController.text = widget.user.fullName;
    if (widget.user.profileImagePath != null) {
      _profileImageFile = File(widget.user.profileImagePath!);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi password jika user ingin mengubah password
      if (_showPasswordFields) {
        if (_currentPasswordController.text != widget.user.password) {
          _showError('Password saat ini tidak benar');
          return;
        }
        
        if (_newPasswordController.text.length < 6) {
          _showError('Password baru minimal 6 karakter');
          return;
        }
        
        if (_newPasswordController.text != _confirmPasswordController.text) {
          _showError('Konfirmasi password tidak cocok');
          return;
        }
      }

      final db = DatabaseHelper.instance;
      bool hasChanges = false;

      // Update profile basic info
      if (_usernameController.text != widget.user.username || 
          _fullNameController.text != widget.user.fullName) {
        
        final updatedUser = widget.user.copyWith(
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim(),
        );

        final profileResult = await db.updateUserProfile(updatedUser);
        if (profileResult > 0) {
          hasChanges = true;
          print('Profile updated successfully');
        } else {
          throw Exception('Failed to update profile');
        }
      }

      // Update password if changed
      if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
        final passwordResult = await db.updateUserPassword(
          widget.user.id, 
          _newPasswordController.text
        );
        
        if (passwordResult > 0) {
          hasChanges = true;
          print('Password updated successfully');
        } else {
          throw Exception('Failed to update password');
        }
      }

      // Update SharedPreferences with new data
      if (hasChanges) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text.trim());
        await prefs.setString('full_name', _fullNameController.text.trim());
        
        _showSuccess('Profile berhasil diperbarui!');
        
        // Return true to indicate changes were made
        Navigator.pop(context, true);
      } else {
        _showInfo('Tidak ada perubahan yang disimpan');
        Navigator.pop(context, false);
      }

    } catch (e) {
      print('Error saving profile: $e');
      _showError('Gagal menyimpan profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      setState(() {
        _isUpdatingPhoto = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUpdatingPhoto = false;
        });
        return;
      }

      final File imageFile = File(image.path);
      final croppedImageBytes = await Navigator.push<List<int>>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropWidget(
            imageFile: imageFile,
            onCropped: (croppedBytes) {
              Navigator.pop(context, croppedBytes);
            },
          ),
        ),
      );

      if (croppedImageBytes == null) {
        setState(() {
          _isUpdatingPhoto = false;
        });
        return;
      }

      final String? savedImagePath = await _saveImageToLocal(croppedImageBytes);

      if (savedImagePath != null) {
        setState(() {
          _profileImageFile = File(savedImagePath);
        });

        // Update user profile in database
        final updatedUser = widget.user.copyWith(profileImagePath: savedImagePath);
        await DatabaseHelper.instance.updateUserProfile(updatedUser);

        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', savedImagePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Gagal menyimpan foto profil');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPhoto = false;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Foto'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (_profileImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfilePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _saveImageToLocal(List<int> imageBytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(path.join(appDir.path, 'profile_images'));

      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Delete old profile image if exists
      if (_profileImageFile != null && await _profileImageFile!.exists()) {
        await _profileImageFile!.delete();
      }

      final fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path.join(profileDir.path, fileName));

      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      setState(() {
        _isUpdatingPhoto = true;
      });

      if (_profileImageFile != null && await _profileImageFile!.exists()) {
        await _profileImageFile!.delete();
      }

      setState(() {
        _profileImageFile = null;
      });

      // Update user profile in database
      final updatedUser = widget.user.copyWith(profileImagePath: null);
      await DatabaseHelper.instance.updateUserProfile(updatedUser);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPhoto = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: _profileImageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImageFile!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primary,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isUpdatingPhoto
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _isUpdatingPhoto ? null : _changeProfilePhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Basic Information Section
                _buildSectionTitle('Informasi Dasar'),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
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
                const SizedBox(height: 16),

                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama lengkap minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Email (Read Only)
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        widget.user.email,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Tidak dapat diubah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password Section
                Row(
                  children: [
                    _buildSectionTitle('Ubah Password'),
                    const Spacer(),
                    Switch(
                      value: _showPasswordFields,
                      onChanged: (value) {
                        setState(() {
                          _showPasswordFields = value;
                          if (!value) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                
                if (_showPasswordFields) ...[
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: _showPasswordFields ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password saat ini harus diisi';
                      }
                      return null;
                    } : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: _showPasswordFields ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru harus diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    } : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: _showPasswordFields ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password harus diisi';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    } : null,
                  ),
                ],
                
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}