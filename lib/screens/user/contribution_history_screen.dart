import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/services/auth_service.dart';
import 'package:biota_2/services/data_service.dart';

class ContributionHistoryScreen extends StatefulWidget {
  const ContributionHistoryScreen({super.key});

  @override
  State<ContributionHistoryScreen> createState() => _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState extends State<ContributionHistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Data> _userContributions = [];
  User? _currentUser;
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
        });
        await _loadUserContributions();
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserContributions() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final db = await _databaseHelper.database;
      final result = await db.query(
        'data',
        where: 'userId = ?',
        whereArgs: [_currentUser!.id],
        orderBy: 'createdAt DESC',
      );

      List<Data> contributions = result.map((map) => Data.fromMap(map)).toList();

      // Filter berdasarkan status yang dipilih
      if (_selectedFilter != 'all') {
        contributions = contributions.where((data) {
          switch (_selectedFilter) {
            case 'pending':
              return data.isApproved == 0;
            case 'approved':
              return data.isApproved == 1;
            case 'rejected':
              return data.isApproved == 3;
            default:
              return true;
          }
        }).toList();
      }

      setState(() {
        _userContributions = contributions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contributions: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contributions: $e')),
        );
      }
    }
  }

  String _getStatusText(int isApproved) {
    switch (isApproved) {
      case 0:
        return 'Menunggu Review';
      case 1:
        return 'Disetujui';
      case 3:
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Color _getStatusColor(int isApproved) {
    switch (isApproved) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int isApproved) {
    switch (isApproved) {
      case 0:
        return Icons.hourglass_empty;
      case 1:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Enhanced delete confirmation with additional info
  Future<void> _showDeleteConfirmationDialog(Data contribution) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Hapus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus kontribusi berikut?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              
              // Species info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contribution.speciesName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            contribution.latinName,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(contribution.isApproved).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(contribution.isApproved),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(contribution.isApproved),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tindakan ini tidak dapat dibatalkan. Data akan dihapus secara permanen.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContribution(contribution);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        );
      },
    );
  }

  Future<void> _deleteContribution(Data contribution) async {
    try {
      print('=== DELETING CONTRIBUTION ===');
      print('User ID: ${_currentUser?.id}');
      print('Contribution User ID: ${contribution.userId}');
      print('Contribution ID: ${contribution.id}');
      print('Contribution Name: ${contribution.speciesName}');
      
      // Double check: pastikan user yang menghapus adalah pemilik data
      if (_currentUser == null || contribution.userId != _currentUser!.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda tidak memiliki izin untuk menghapus data ini'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Menghapus data...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Delete from database
      final result = await _databaseHelper.deleteData(contribution.id!);
      print('Delete result: $result');
      
      if (result > 0) {
        // Delete associated image file if exists
        if (contribution.image != null && contribution.image!.isNotEmpty) {
          try {
            final imageFile = File(contribution.image!);
            if (await imageFile.exists()) {
              await imageFile.delete();
              print('Associated image file deleted: ${contribution.image}');
            }
          } catch (e) {
            print('Error deleting image file: $e');
            // Continue even if image deletion fails
          }
        }

        // ✅ NOTIFY DATA SERVICE ABOUT THE CHANGE
        DataService().notifyDataChanged();

        if (mounted) {
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kontribusi "${contribution.speciesName}" berhasil dihapus',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          // Refresh the list
          await _loadUserContributions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus data. Data mungkin sudah tidak ada.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting contribution: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal menghapus kontribusi: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Check if user can delete the contribution
  bool _canDeleteContribution(Data contribution) {
    return _currentUser != null && 
           contribution.userId == _currentUser!.id;
  }

  void _showContributionDetail(Data contribution) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header with status and delete action
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(contribution.isApproved).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(contribution.isApproved),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(contribution.isApproved),
                              size: 16,
                              color: _getStatusColor(contribution.isApproved),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(contribution.isApproved),
                              style: TextStyle(
                                color: _getStatusColor(contribution.isApproved),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Delete button (only for own contributions)
                      if (_canDeleteContribution(contribution))
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context); // Close detail sheet first
                            _showDeleteConfirmationDialog(contribution);
                          },
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Hapus kontribusi',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Species Image
                  if (contribution.image != null && File(contribution.image!).existsSync())
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(contribution.image!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Species name and details
                  Text(
                    contribution.speciesName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    contribution.latinName,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category and habitat
                  Row(
                    children: [
                      Icon(
                        contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contribution.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contribution.habitat,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contribution.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  
                  if (contribution.funFact != null && contribution.funFact!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Fakta Menarik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contribution.funFact!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Date submitted
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Diajukan: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(contribution.createdAt))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Kontribusi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua', Icons.list),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Menunggu', Icons.hourglass_empty),
                      const SizedBox(width: 8),
                      _buildFilterChip('approved', 'Disetujui', Icons.check_circle),
                      const SizedBox(width: 8),
                      _buildFilterChip('rejected', 'Ditolak', Icons.cancel),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _userContributions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUserContributions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _userContributions.length,
                          itemBuilder: (context, index) {
                            return _buildContributionCard(_userContributions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadUserContributions();
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Belum ada kontribusi';
    String submessage = 'Mulai berkontribusi dengan menambahkan data spesies';
    IconData iconData = Icons.nature_people;

    if (_selectedFilter != 'all') {
      switch (_selectedFilter) {
        case 'pending':
          message = 'Tidak ada data yang menunggu review';
          submessage = 'Data yang menunggu persetujuan akan muncul di sini';
          break;
        case 'approved':
          message = 'Belum ada data yang disetujui';
          submessage = 'Data yang telah disetujui akan muncul di sini';
          break;
        case 'rejected':
          message = 'Tidak ada data yang ditolak';
          submessage = 'Data yang ditolak akan muncul di sini';
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(Data contribution) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showContributionDetail(contribution),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(contribution.isApproved).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(contribution.isApproved).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(contribution.isApproved),
                          size: 14,
                          color: _getStatusColor(contribution.isApproved),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(contribution.isApproved),
                          style: TextStyle(
                            color: _getStatusColor(contribution.isApproved),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.parse(contribution.createdAt)),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Species info
              Row(
                children: [
                  // Species image or icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: contribution.image != null && File(contribution.image!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(contribution.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                                  color: Colors.grey[400],
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Species details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contribution.speciesName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contribution.latinName,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              contribution.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              contribution.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions (only show delete for user's own contributions)
                  if (_canDeleteContribution(contribution))
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmationDialog(contribution);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(Icons.more_vert, color: Colors.grey[600]),
                    )
                  else
                    // Show info icon for non-deletable items
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description preview
              Text(
                contribution.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}