import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/screens/auth/login_screen.dart';
import 'package:biota_2/screens/user/edit_profile_screen.dart';
import 'package:biota_2/screens/user/contribution_history_screen.dart';
import 'package:biota_2/screens/user/about_app_screen.dart';
import 'package:biota_2/widgets/image_crop_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        final user = await DatabaseHelper.instance.getUserById(userId);
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorAndLogout('Session expired');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
      _showErrorAndLogout('Error loading profile');
    }
  }

  void _showErrorAndLogout(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _logout();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    // Jika ada perubahan, reload data user
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_currentUser == null) return;

    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      setState(() {
        _isUpdatingPhoto = true;
      });

      // Pick image
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

      // Show crop screen
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

      // Save cropped image to local storage
      final String? savedImagePath = await _saveImageToLocal(croppedImageBytes);
      
      if (savedImagePath != null) {
        // Update user profile with new image path
        final updatedUser = _currentUser!.copyWith(
          profileImagePath: savedImagePath,
        );

        final result = await DatabaseHelper.instance.updateUserProfile(updatedUser);
        
        if (result > 0) {
          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_path', savedImagePath);
          
          // Update local state
          setState(() {
            _currentUser = updatedUser;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto profil berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Gagal memperbarui foto profil di database');
        }
      } else {
        throw Exception('Gagal menyimpan foto profil');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              if (_currentUser?.profileImagePath != null)
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
      if (_currentUser?.profileImagePath != null) {
        final oldFile = File(_currentUser!.profileImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      
      final fileName = 'profile_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path.join(profileDir.path, fileName));
      
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<void> _removeProfilePhoto() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isUpdatingPhoto = true;
      });

      // Delete image file if exists
      if (_currentUser!.profileImagePath != null) {
        final imageFile = File(_currentUser!.profileImagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Update user profile
      final updatedUser = _currentUser!.copyWith(
        profileImagePath: null,
      );

      final result = await DatabaseHelper.instance.updateUserProfile(updatedUser);
      
      if (result > 0) {
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profile_image_path');
        
        // Update local state
        setState(() {
          _currentUser = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Gagal menghapus foto profil dari database');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _currentUser == null
              ? const Center(
                  child: Text('Error loading profile'),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return CustomScrollView(
      slivers: [
        // Profile Header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Picture with Change Button
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: _currentUser!.profileImagePath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_currentUser!.profileImagePath!),
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
                        // Change Photo Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUpdatingPhoto ? null : _changeProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isUpdatingPhoto
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // User Name
                    Text(
                      _currentUser!.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Text(
                      '${_currentUser!.username}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Text(
                      _currentUser!.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Profile Menu
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMenuCard(
                icon: Icons.edit,
                title: 'Edit Profile',
                subtitle: 'Ubah informasi profil Anda',
                onTap: _navigateToEditProfile,
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.history,
                title: 'Riwayat Kontribusi',
                subtitle: 'Lihat data yang telah Anda kirim',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContributionHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi versi dan pengembang',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutAppScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildLogoutButton(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}