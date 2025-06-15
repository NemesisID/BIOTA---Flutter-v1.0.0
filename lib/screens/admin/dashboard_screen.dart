import 'package:flutter/material.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/services/auth_service.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/screens/auth/login_screen.dart';
import 'package:biota_2/screens/admin/species_management_screen.dart';
import 'package:biota_2/screens/admin/event_management_screen.dart';
import 'package:biota_2/screens/admin/user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  // Sample stats data (in real app, fetch from database)
  int totalSpecies = 0;
  int pendingSpecies = 0;
  int totalUsers = 0;
  int totalEvents = 8;
  
  // Fun fact data
  Map<String, dynamic>? currentFunFact;
  bool isLoadingFunFact = false;
  
  // ✅ TAMBAH: Loading states untuk refresh
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ✅ TAMBAH: Method untuk refresh data dashboard
  Future<void> _refreshDashboardData() async {
    print('=== REFRESHING DASHBOARD DATA ===');
    setState(() => isLoadingStats = true);
    
    try {
      await Future.wait([
        _loadStats(),
        _loadFunFact(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data dashboard berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingStats = false);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    await _loadStats();
    await _loadFunFact();
  }

  Future<void> _loadStats() async {
    try {
      print('Loading dashboard stats...');
      final speciesStats = await DatabaseHelper.instance.getSpeciesStats();
      final userStats = await DatabaseHelper.instance.getUserStats();
      
      if (mounted) {
        setState(() {
          totalSpecies = speciesStats['total'] ?? 0;
          pendingSpecies = speciesStats['pending'] ?? 0;
          totalUsers = userStats['total'] ?? 0;
        });
      }
      print('Stats loaded - Species: $totalSpecies, Pending: $pendingSpecies, Users: $totalUsers');
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadFunFact() async {
    setState(() => isLoadingFunFact = true);
    try {
      final funFact = await DatabaseHelper.instance.getFunFact();
      if (mounted) {
        setState(() {
          currentFunFact = funFact;
          isLoadingFunFact = false;
        });
      }
      print('Loaded fun fact: $funFact');
    } catch (e) {
      print('Error loading fun fact: $e');
      if (mounted) {
        setState(() => isLoadingFunFact = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/logo/logo.png',
                height: 28,
                width: 28,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        // ✅ TAMBAH: Action button untuk refresh
        actions: _selectedIndex == 0 ? [
          IconButton(
            onPressed: isLoadingStats ? null : _refreshDashboardData,
            icon: isLoadingStats 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
        ] : null,
      ),
      drawer: _buildDrawer(),
      body: _getSelectedScreen(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin BIOTA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Panel Administrasi',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                  badge: null,
                ),
                _buildMenuItem(
                  icon: Icons.pets,
                  title: 'Kelola Spesies',
                  index: 1,
                  badge: pendingSpecies > 0 ? pendingSpecies.toString() : null,
                ),
                _buildMenuItem(
                  icon: Icons.event,
                  title: 'Kelola Event',
                  index: 2,
                  badge: null,
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Kelola User',
                  index: 3,
                  badge: null,
                ),
                const Divider(height: 20),
              ],
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _showLogoutDialog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tileColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardHome();
      case 1: return const SpeciesManagementScreen();
      case 2: return const EventManagementScreen();
      case 3: return const UserManagementScreen();
      default: return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    // ✅ TAMBAH: RefreshIndicator untuk dashboard home
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // ✅ PENTING: Pastikan bisa di-scroll meski konten pendek
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Panel Administrasi BIOTA',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ✅ TAMBAH: Loading indicator untuk stats
                      if (isLoadingStats)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kelola data spesies, event, pengguna, dan konten fun facts untuk aplikasi BIOTA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  // ✅ TAMBAH: Pull to refresh hint
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tarik ke bawah untuk refresh data',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Fun Fact Management Section
            Row(
              children: [
                const Text(
                  'Fun Fact Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showEditFunFactDialog,
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: 'Edit Fun Fact',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildFunFactCard(),
            
            const SizedBox(height: 24),
            
            // Statistics Cards
            Row(
              children: [
                const Text(
                  'Statistik Aplikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // ✅ TAMBAH: Timestamp last update
                if (!isLoadingStats)
                  Text(
                    'Terakhir diperbarui: ${_getCurrentTime()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics Cards dengan loading state
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Spesies',
                        value: isLoadingStats ? '...' : totalSpecies.toString(),
                        icon: Icons.pets,
                        color: Colors.green,
                        onTap: () => setState(() => _selectedIndex = 1),
                        isLoading: isLoadingStats,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Menunggu Review',
                        value: isLoadingStats ? '...' : pendingSpecies.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        badge: !isLoadingStats && pendingSpecies > 0,
                        onTap: () => setState(() => _selectedIndex = 1),
                        isLoading: isLoadingStats,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Pengguna',
                        value: isLoadingStats ? '...' : totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () => setState(() => _selectedIndex = 3),
                        isLoading: isLoadingStats,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Event Aktif',
                        value: totalEvents.toString(),
                        icon: Icons.event,
                        color: Colors.purple,
                        onTap: () => setState(() => _selectedIndex = 2),
                        isLoading: false, // Event tidak perlu loading karena data dummy
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    title: 'Review Spesies',
                    subtitle: '$pendingSpecies menunggu',
                    icon: Icons.rate_review,
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    title: 'Buat Event',
                    subtitle: 'Event baru',
                    icon: Icons.add_circle,
                    color: Colors.green,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    title: 'Update Fun Fact',
                    subtitle: 'Edit konten',
                    icon: Icons.lightbulb_outline,
                    color: Colors.blue,
                    onTap: _showEditFunFactDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    title: 'Kelola User',
                    subtitle: 'Atur pengguna',
                    icon: Icons.manage_accounts,
                    color: Colors.purple,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ),
              ],
            ),
            
            // ✅ TAMBAH: Extra space agar scroll bisa sampai bawah
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ✅ TAMBAH: Method untuk mendapatkan waktu sekarang
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFunFactCard() {
    if (isLoadingFunFact) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (currentFunFact == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada Fun Fact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap tombol edit untuk menambahkan fun fact pertama',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final String backgroundColorName = currentFunFact!['backgroundColor'] ?? 'blue';
    final String iconName = currentFunFact!['icon'] ?? 'water';
    
    Color backgroundColor = _getFunFactBackgroundColor(backgroundColorName);
    IconData iconData = _getFunFactIcon(iconName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor.withOpacity(0.1),
            backgroundColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentFunFact!['title'] ?? 'Fun Fact',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terakhir diupdate: ${_formatDate(currentFunFact!['updatedAt'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentFunFact!['description'] ?? 'Deskripsi fun fact',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showEditFunFactDialog() {
    final titleController = TextEditingController(
      text: currentFunFact?['title'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: currentFunFact?['description'] ?? '',
    );
    
    String selectedIcon = currentFunFact?['icon'] ?? 'water';
    String selectedBackground = currentFunFact?['backgroundColor'] ?? 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Edit Fun Fact'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  const Text(
                    'Judul Fun Fact',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan judul yang menarik...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description Input
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan fun fact yang menarik...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Icon Selection
                  const Text(
                    'Pilih Icon',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildIconOption('water', Icons.water_drop, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('leaf', Icons.eco, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('animal', Icons.pets, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('tree', Icons.park, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('earth', Icons.public, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('recycle', Icons.recycling, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('star', Icons.star, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('favorite', Icons.favorite, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('celebration', Icons.celebration, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('nature', Icons.nature, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                      _buildIconOption('forest', Icons.forest, selectedIcon, (newIcon) {
                        setDialogState(() {
                          selectedIcon = newIcon;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Background Color Selection
                  const Text(
                    'Pilih Warna Latar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildColorOption('blue', Colors.blue, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('green', Colors.green, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('orange', Colors.orange, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('purple', Colors.purple, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('teal', Colors.teal, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('indigo', Colors.indigo, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('pink', Colors.pink, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                      _buildColorOption('red', Colors.red, selectedBackground, (newColor) {
                        setDialogState(() {
                          selectedBackground = newColor;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || 
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Judul dan deskripsi tidak boleh kosong'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  await DatabaseHelper.instance.updateFunFact(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    icon: selectedIcon,
                    backgroundColor: selectedBackground,
                  );
                  
                  Navigator.pop(context);
                  await _loadFunFact();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fun fact berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildIconOption(String value, IconData icon, String selectedIcon, Function(String) onSelected) {
    final isSelected = selectedIcon == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      )
    );
  }

  Widget _buildColorOption(String value, Color color, String selectedBackground, Function(String) onSelected) {
    final isSelected = selectedBackground == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.circle,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Color _getFunFactBackgroundColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'pink': return Colors.pink;
      case 'red': return Colors.red;
      case 'blue':
      default: return Colors.blue;
    }
  }

  IconData _getFunFactIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'leaf': return Icons.eco;
      case 'animal': return Icons.pets;
      case 'tree': return Icons.park;
      case 'earth': return Icons.public;
      case 'recycle': return Icons.recycling;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'celebration': return Icons.celebration;
      case 'nature': return Icons.nature;
      case 'eco': return Icons.eco;
      case 'forest': return Icons.forest;
      case 'pets': return Icons.pets;
      case 'water':
      default: return Icons.water_drop;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tidak diketahui';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool badge = false,
    VoidCallback? onTap,
    bool isLoading = false, // ✅ TAMBAH: Parameter loading
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (badge)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                // ✅ TAMBAH: Loading indicator untuk card
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.instance.logout();
                await AuthService.instance.clearLoginStatus();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
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
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Kelola Spesies';
      case 2: return 'Kelola Event';
      case 3: return 'Kelola User';
      default: return 'Dashboard';
    }
  }
}