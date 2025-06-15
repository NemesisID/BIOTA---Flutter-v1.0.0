import 'package:flutter/material.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/models/user.dart';
import 'dart:io';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<User> allUsers = [];
  List<User> regularUsers = [];
  List<User> adminUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    
    try {
      print('=== LOADING USER DATA ===');
      
      final users = await DatabaseHelper.instance.getAllUsers();
      
      print('Total users loaded: ${users.length}');
      
      // Debug: Print all users
      for (var user in users) {
        print('User: ${user.username}');
        print('  ID: ${user.id}');
        print('  Email: ${user.email}');
        print('  Full Name: ${user.fullName}');
        print('  Is Admin: ${user.isAdmin}');
        print('  Profile Image: ${user.profileImagePath}');
        print('  Created: ${user.createdAt}');
        print('  ---');
      }
      
      setState(() {
        allUsers = users;
        regularUsers = users.where((user) => !user.isAdmin).toList();
        adminUsers = users.where((user) => user.isAdmin).toList();
        isLoading = false;
      });
      
      print('=== FILTERED RESULTS ===');
      print('Regular Users: ${regularUsers.length}');
      print('Admin Users: ${adminUsers.length}');
      
    } catch (e) {
      print('Error loading users: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ IMPLEMENTASI _deleteUser METHOD YANG LENGKAP
  Future<void> _deleteUser(User user) async {
    final confirm = await _showConfirmDialog(
      'Hapus User',
      'Apakah Anda yakin ingin menghapus user "${user.username}"?\n\nSemua data yang terkait dengan user ini akan ikut terhapus!\n\nTindakan ini tidak dapat dibatalkan!',
      'Hapus',
      Colors.red,
    );

    if (confirm) {
      try {
        print('=== DELETING USER ===');
        print('User ID: ${user.id}');
        print('Username: ${user.username}');
        
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
        
        // Delete from database
        final result = await DatabaseHelper.instance.deleteUser(user.id!);
        
        // Hide loading dialog
        Navigator.pop(context);
        
        if (result > 0) {
          print('✅ User deleted successfully from database');
          _showSuccessSnackBar('✅ User "${user.username}" berhasil dihapus');
          await _loadUserData(); // Refresh data setelah delete
        } else {
          throw Exception('User tidak ditemukan atau sudah terhapus');
        }
        
      } catch (e) {
        // Hide loading dialog if still showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        print('❌ Error deleting user: $e');
        _showErrorSnackBar('❌ Error: ${e.toString()}');
      }
    }
  }

  // ✅ IMPLEMENTASI _showConfirmDialog METHOD
  Future<bool> _showConfirmDialog(String title, String content, String actionText, Color actionColor) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              actionColor == Colors.green ? Icons.check_circle :
              actionColor == Colors.red ? Icons.warning : Icons.info,
              color: actionColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (actionColor == Colors.red) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan: Tindakan ini tidak dapat dikembalikan!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    ) ?? false; // Return false jika dialog ditutup tanpa pilihan
  }

  // ✅ IMPLEMENTASI HELPER METHODS UNTUK SNACKBAR
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // ✅ IMPLEMENTASI _getFilteredUsers METHOD
  List<User> _getFilteredUsers(List<User> users) {
    if (searchQuery.isEmpty) return users;

    return users.where((user) {
      final searchLower = searchQuery.toLowerCase();
      return user.username.toLowerCase().contains(searchLower) ||
             user.email.toLowerCase().contains(searchLower) ||
             user.fullName.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari user berdasarkan username, email, atau nama...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'User Biasa (${regularUsers.length})',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Admin (${adminUsers.length})',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar View
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Memuat data pengguna...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersList(_getFilteredUsers(regularUsers), 'regular'),
                      _buildUsersList(_getFilteredUsers(adminUsers), 'admin'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ PERBAIKI: Method _buildUsersList dengan kurung kurawal yang benar
  Widget _buildUsersList(List<User> users, String type) {
    if (users.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadUserData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == 'regular' ? Icons.people_outline : Icons.admin_panel_settings_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'regular' ? 'Tidak ada user biasa' : 'Tidak ada admin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      searchQuery.isNotEmpty ? 'Coba kata kunci pencarian lain' : 
                      'Tarik ke bawah untuk refresh data',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadUserData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user, type);
        },
      ),
    );
  } // ✅ PERBAIKI: Tutup method dengan benar

  Widget _buildUserCard(User user, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile image and basic info
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user.isAdmin ? Colors.orange : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(user.profileImagePath, user.fullName),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isAdmin ? Colors.orange : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isAdmin ? 'ADMIN' : 'USER',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.fingerprint, 'User ID', user.id.toString()),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.access_time, 'Terdaftar', _formatDate(user.createdAt)),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.verified_user, 
                  'Status', 
                  user.isAdmin ? 'Administrator' : 'Pengguna Biasa',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Action Buttons - HAPUS TOMBOL EDIT, HANYA DETAIL DAN HAPUS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetail(user),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Hapus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ IMPLEMENTASI METHOD YANG MASIH KURANG
  void _showUserDetail(User user) {
    bool showPassword = false; // State untuk toggle password visibility
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: user.isAdmin ? Colors.orange : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildProfileImage(user.profileImagePath, user.fullName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user.username}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image (larger)
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: user.isAdmin ? Colors.orange : AppColors.primary,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildProfileImage(user.profileImagePath, user.fullName),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // User Details
                  _buildDetailRow(Icons.fingerprint, 'User ID', user.id.toString()),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.person, 'Username', user.username),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.badge, 'Nama Lengkap', user.fullName),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.email, 'Email', user.email),
                  const SizedBox(height: 12),
                  
                  // ✅ TAMBAH: Password Row dengan Toggle Visibility
                  Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Password: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                showPassword ? user.password : '•' * user.password.length,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: showPassword ? null : 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  showPassword = !showPassword;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  showPassword ? Icons.visibility_off : Icons.visibility,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailRow(
                    Icons.admin_panel_settings, 
                    'Status', 
                    user.isAdmin ? 'Administrator' : 'Pengguna Biasa',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time, 'Terdaftar', _formatDate(user.createdAt)),
                  
                  // ✅ TAMBAH: Security Warning untuk Password
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.orange[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password ditampilkan untuk keperluan administrasi. Jaga kerahasiaan informasi ini.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imagePath, String fullName) {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        if (imagePath.startsWith('http')) {
          return Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildAvatarFallback(fullName);
            },
          );
        } else {
          return Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildAvatarFallback(fullName);
            },
          );
        }
      } catch (e) {
        return _buildAvatarFallback(fullName);
      }
    } else {
      return _buildAvatarFallback(fullName);
    }
  }

  Widget _buildAvatarFallback(String fullName) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}