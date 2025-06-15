import 'package:flutter/material.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/models/user.dart';
import 'dart:io';

class SpeciesManagementScreen extends StatefulWidget {
  const SpeciesManagementScreen({super.key});

  @override
  State<SpeciesManagementScreen> createState() => _SpeciesManagementScreenState();
}

class _SpeciesManagementScreenState extends State<SpeciesManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Data> pendingSpecies = [];
  List<Data> approvedSpecies = [];
  List<Data> rejectedSpecies = [];
  bool isLoading = true;
  String searchQuery = '';
  
  // Map untuk menyimpan username berdasarkan user ID
  Map<int, String> userMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSpeciesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method untuk load user data dan membuat map
  Future<void> _loadUserMap() async {
    try {
      print('=== LOADING USERS ===');
      final users = await DatabaseHelper.instance.getAllUsers();
      userMap.clear();
      
      print('Total users loaded: ${users.length}');
      
      for (var user in users) {
        if (user.id != null) {
          userMap[user.id!] = user.username;
          print('User mapping: ${user.id} -> ${user.username}');
        }
      }
      
      print('User map completed: $userMap');
      
    } catch (e) {
      print('Error loading users: $e');
      userMap.clear();
    }
  }

  // Method untuk mendapatkan username dari user ID
  String _getUsernameFromId(int userId) {
    print('Getting username for user ID: $userId');
    
    final username = userMap[userId];
    if (username != null && username.isNotEmpty) {
      print('Found username: $username for user ID: $userId');
      return username;
    }
    
    print('Username not found for user ID: $userId, available users: ${userMap.keys.toList()}');
    return 'User #$userId';
  }

  // Method untuk load species data
  Future<void> _loadSpeciesData() async {
    setState(() => isLoading = true);
    
    try {
      print('=== LOADING SPECIES DATA ===');
      
      // Load user data terlebih dahulu
      await _loadUserMap();
      
      // Kemudian load species data
      final allSpecies = await DatabaseHelper.instance.getAllData();
      
      print('Total species loaded: ${allSpecies.length}');
      
      // Debug: Print semua data yang diload dengan username
      for (var species in allSpecies) {
        final username = _getUsernameFromId(species.userId);
        print('Species: ${species.speciesName}');
        print('  Latin: ${species.latinName}');
        print('  isApproved: ${species.isApproved}');
        print('  User ID: ${species.userId}');
        print('  Username: $username');
        print('  Created: ${species.createdAt}');
        print('  ---');
      }
      
      // Filter berdasarkan isApproved integer
      setState(() {
        // 0 = Pending, 1 = Approved, 3 = Rejected
        pendingSpecies = allSpecies.where((s) => s.isApproved == 0).toList();
        approvedSpecies = allSpecies.where((s) => s.isApproved == 1).toList();
        rejectedSpecies = allSpecies.where((s) => s.isApproved == 3).toList();
        isLoading = false;
      });
      
      // Debug: Print filtered results
      print('=== FILTERED RESULTS ===');
      print('Pending (isApproved=0): ${pendingSpecies.length}');
      print('Approved (isApproved=1): ${approvedSpecies.length}');
      print('Rejected (isApproved=3): ${rejectedSpecies.length}');
      
    } catch (e) {
      print('Error loading species: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method untuk update status species
  Future<void> _updateSpeciesStatus(Data species, String action) async {
    try {
      int newStatus;
      switch (action) {
        case 'Approved':
          newStatus = 1;
          break;
        case 'Rejected':
          newStatus = 3;
          break;
        default:
          newStatus = 0; // Pending
      }
      
      print('Updating species ${species.id} to status $newStatus ($action)');
      
      await DatabaseHelper.instance.updateSpeciesApprovalStatus(species.id!, newStatus);
      await _loadSpeciesData();
      
      String actionText = action == 'Approved' ? 'disetujui' : 'ditolak';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spesies "${species.speciesName}" berhasil $actionText'),
            backgroundColor: action == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating species status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method untuk delete species
  Future<void> _deleteSpecies(Data species) async {
    final confirm = await _showConfirmDialog(
      'Hapus Spesies',
      'Apakah Anda yakin ingin menghapus "${species.speciesName}"?\n\nTindakan ini tidak dapat dibatalkan!',
      'Hapus',
      Colors.red,
    );
    
    if (confirm) {
      try {
        print('Deleting species ${species.id}');
        await DatabaseHelper.instance.deleteData(species.id!);
        await _loadSpeciesData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${species.speciesName} berhasil dihapus'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error deleting species: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Method untuk menampilkan dialog konfirmasi
  Future<bool> _showConfirmDialog(String title, String content, String actionText, Color actionColor) async {
    return await showDialog<bool>(
      context: context,
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
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    ) ?? false;
  }

  // Method untuk filter species berdasarkan search query
  List<Data> _getFilteredSpecies(List<Data> species) {
    if (searchQuery.isEmpty) return species;
    
    return species.where((species) {
      final searchLower = searchQuery.toLowerCase();
      final username = _getUsernameFromId(species.userId);
      
      final nameMatch = species.speciesName.toLowerCase().contains(searchLower);
      final latinMatch = species.latinName.toLowerCase().contains(searchLower);
      final habitatMatch = species.habitat.toLowerCase().contains(searchLower);
      final categoryMatch = species.category.toLowerCase().contains(searchLower);
      final usernameMatch = username.toLowerCase().contains(searchLower);
      
      return nameMatch || latinMatch || habitatMatch || categoryMatch || usernameMatch;
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
                hintText: 'Cari spesies, nama latin, habitat, kategori, atau username...',
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
                      const Icon(Icons.pending_actions, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Pending (${pendingSpecies.length})',
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
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Disetujui (${approvedSpecies.length})',
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
                      const Icon(Icons.cancel, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Ditolak (${rejectedSpecies.length})',
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
              isScrollable: false,
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
                        Text('Memuat data spesies...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSpeciesList(_getFilteredSpecies(pendingSpecies), 'pending'),
                      _buildSpeciesList(_getFilteredSpecies(approvedSpecies), 'approved'),
                      _buildSpeciesList(_getFilteredSpecies(rejectedSpecies), 'rejected'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Method untuk build species list DENGAN RefreshIndicator
  Widget _buildSpeciesList(List<Data> species, String type) {
    if (species.isEmpty) {
      // ✅ UNTUK EMPTY STATE, TETAP GUNAKAN RefreshIndicator DENGAN CUSTOM SCROLL
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadSpeciesData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // ✅ ENABLE SCROLL MESKI KOSONG
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == 'pending' ? Icons.pending_actions :
                      type == 'approved' ? Icons.check_circle_outline :
                      Icons.cancel_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'pending' ? 'Tidak ada spesies yang menunggu review' :
                      type == 'approved' ? 'Belum ada spesies yang disetujui' :
                      'Belum ada spesies yang ditolak',
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

    // ✅ UNTUK LIST YANG ADA ISI, GUNAKAN RefreshIndicator + ListView
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSpeciesData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(), // ✅ ENABLE REFRESH GESTURE
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: species.length,
        itemBuilder: (context, index) {
          final speciesData = species[index];
          return _buildSpeciesCard(speciesData, type);
        },
      ),
    );
  }

  // Method untuk build species card
  Widget _buildSpeciesCard(Data species, String type) {
    Color statusColor = _getStatusColor(species.isApproved);
    IconData categoryIcon = _getCategoryIcon(species.category);
    
    String submittedBy = _getUsernameFromId(species.userId);
    String statusText = _getStatusText(species.isApproved);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail gambar jika ada
            if (species.image != null && species.image!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildSpeciesImage(species.image!),
                ),
              ),
            ],
            
            // Header with status and category
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species.speciesName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        species.latinName,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Species Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.category, 'Kategori', species.category),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.location_on, 'Habitat', species.habitat),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.person, 
                  'Diajukan oleh', 
                  submittedBy,
                  isUser: true,
                ),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.access_time, 'Tanggal', _formatDate(species.createdAt)),
              ],
            ),
            
            if (species.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Deskripsi:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                species.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSpeciesDetail(species),
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
                
                if (type == 'pending') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSpeciesStatus(species, 'Approved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSpeciesStatus(species, 'Rejected'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak'),
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
                
                if (type != 'pending') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteSpecies(species),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk show species detail
  void _showSpeciesDetail(Data species) {
    String submittedBy = _getUsernameFromId(species.userId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getCategoryIcon(species.category), color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.speciesName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    species.latinName,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
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
                // Gambar
                if (species.image != null && species.image!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildSpeciesImage(species.image!),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada gambar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Detail informasi dengan username yang benar
                _buildDetailRow(Icons.category, 'Kategori', species.category),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on, 'Habitat', species.habitat),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.info, 'Status Konservasi', species.status),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.approval, 'Status Approval', _getStatusText(species.isApproved)),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.person, 'Diajukan oleh', submittedBy, isUser: true),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.fingerprint, 'User ID', species.userId.toString()),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.access_time, 'Tanggal pengajuan', _formatDate(species.createdAt)),
                if (species.latitude != null && species.longitude != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_pin, 'Koordinat', 
                    '${species.latitude!.toStringAsFixed(6)}, ${species.longitude!.toStringAsFixed(6)}'),
                ],
                if (species.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    species.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (species.image != null && species.image!.isNotEmpty)
            TextButton(
              onPressed: () => _showFullSizeImage(species.image!, species.speciesName),
              child: const Text('Lihat Gambar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Method untuk format tanggal
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Method untuk build detail row
  Widget _buildDetailRow(IconData icon, String label, String value, {bool isUser = false}) {
    bool isUnknownUser = isUser && value.startsWith('User #');
    
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
              color: isUnknownUser ? Colors.orange[600] : Colors.grey[600],
              fontWeight: isUser && !isUnknownUser ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Method untuk build species image
  Widget _buildSpeciesImage(String imagePath) {
    print('Loading image from path: $imagePath');
    
    try {
      if (imagePath.startsWith('http')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return _buildImageErrorWidget();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading local image: $error');
            return _buildImageErrorWidget();
          },
        );
      }
    } catch (e) {
      print('Exception loading image: $e');
      return _buildImageErrorWidget();
    }
  }

  // Method untuk build image error widget
  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk show full size image
  void _showFullSizeImage(String imagePath, String speciesName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                speciesName,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildSpeciesImage(imagePath),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method untuk get status color
  Color _getStatusColor(int isApproved) {
    switch (isApproved) {
      case 1: // Approved
        return Colors.green;
      case 3: // Rejected
        return Colors.red;
      case 0: // Pending
      default:
        return Colors.orange;
    }
  }

  // Method untuk get status text
  String _getStatusText(int isApproved) {
    switch (isApproved) {
      case 1:
        return 'Disetujui';
      case 3:
        return 'Ditolak';
      case 0:
      default:
        return 'Menunggu Review';
    }
  }

  // Method untuk get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hewan':
        return Icons.pets;
      case 'tumbuhan':
        return Icons.eco;
      case 'mamalia':
        return Icons.pets;
      case 'burung':
        return Icons.air;
      case 'reptil':
        return Icons.bug_report;
      case 'ikan':
        return Icons.water;
      case 'serangga':
        return Icons.bug_report;
      default:
        return Icons.pets;
    }
  }
}