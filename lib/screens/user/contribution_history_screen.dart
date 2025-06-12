import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/services/auth_service.dart';

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

  Future<void> _showDeleteConfirmationDialog(Data contribution) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah Anda yakin ingin menghapus kontribusi "${contribution.speciesName}"?'),
              const SizedBox(height: 8),
              Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContribution(contribution);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteContribution(Data contribution) async {
    try {
      final result = await _databaseHelper.deleteData(contribution.id!);
      if (result > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kontribusi berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserContributions(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kontribusi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  
                  // Actions
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
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
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