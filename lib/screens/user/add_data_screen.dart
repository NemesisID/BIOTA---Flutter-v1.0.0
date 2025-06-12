import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/data.dart';
import '../../services/database_helper.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../models/user.dart'; // Pastikan User model diimport

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesNameController = TextEditingController();
  final _latinNameController = TextEditingController();
  final _habitatController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _funFactController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  String _selectedCategory = 'Hewan';
  String _selectedStatus = 'Aman'; // Default status
  File? _selectedImage;
  bool _isLoading = false;
  User? _currentUser;

  final List<String> _categories = ['Hewan', 'Tumbuhan'];
  final List<String> _statusOptions = [
    'Aman',
    'Rentan', 
    'Terancam Punah',
    'Kritis',
    'Punah di Alam Liar',
    'Punah'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _speciesNameController.dispose();
    _latinNameController.dispose();
    _habitatController.dispose();
    _descriptionController.dispose();
    _funFactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pilih Sumber Gambar'),
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
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih gambar: $e')),
        );
      }
    }
  }

  Future<String?> _saveImageToLocal(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'species_images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy(path.join(imagesDir.path, fileName));
      
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aman': return Colors.green.shade600;
      case 'rentan': return Colors.yellow.shade700;
      case 'terancam punah': return Colors.orange.shade700;
      case 'kritis': return Colors.red.shade700;
      case 'punah di alam liar': return Colors.purple.shade700;
      case 'punah': return Colors.black87;
      default: return Colors.grey.shade600;
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentUser == null) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User tidak ditemukan. Silakan login ulang.')),
        );
      }
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? imagePath;
      if (_selectedImage != null) {
        imagePath = await _saveImageToLocal(_selectedImage!);
      }

      final double? latitude = double.tryParse(_latitudeController.text.trim());
      final double? longitude = double.tryParse(_longitudeController.text.trim());

      final data = Data(
        image: imagePath,
        speciesName: _speciesNameController.text.trim(),
        latinName: _latinNameController.text.trim(),
        category: _selectedCategory,
        habitat: _habitatController.text.trim(),
        status: _selectedStatus,
        description: _descriptionController.text.trim(),
        funFact: _funFactController.text.trim().isEmpty ? null : _funFactController.text.trim(),
        userId: _currentUser!.id!, // Simpan ID user yang mengupload
        isApproved: 0, 
        createdAt: DateTime.now().toIso8601String(),
        latitude: latitude,
        longitude: longitude,
      );

      await DatabaseHelper.instance.insertData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disubmit! Menunggu persetujuan admin.'),
            backgroundColor: Colors.green,
          ),
        );
        
        _formKey.currentState!.reset();
        _speciesNameController.clear();
        _latinNameController.clear();
        _habitatController.clear();
        _descriptionController.clear();
        _funFactController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        setState(() {
          _selectedImage = null;
          _selectedCategory = 'Hewan';
          _selectedStatus = 'Aman';
        });
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Foto Spesies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Text(' (Opsional)', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 48),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk memilih gambar', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text('Hapus Gambar', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool requiredField = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (requiredField ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ), 
        validator: requiredField ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label tidak boleh kosong';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    Color? Function(String)? getItemColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Row(
              children: [
                if (getItemColor != null)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: getItemColor(item),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (getItemColor != null) const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: '$label *',
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Data Spesies Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data yang Anda kirim akan ditinjau oleh Admin sebelum dipublikasikan.',
                        style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildImagePickerCard(),

              _buildSectionTitle('Informasi Dasar', Icons.article_outlined),
              _buildTextField(
                controller: _speciesNameController,
                label: 'Nama Spesies',
                hint: 'Contoh: Harimau Sumatra',
                icon: Icons.grass_outlined,
              ),
              _buildTextField(
                controller: _latinNameController,
                label: 'Nama Latin',
                hint: 'Contoh: Panthera tigris sumatrae',
                icon: Icons.science_outlined,
              ),

              _buildSectionTitle('Klasifikasi & Status', Icons.category_outlined),
              _buildDropdownField(
                label: 'Kategori',
                value: _selectedCategory,
                items: _categories,
                icon: _selectedCategory == 'Hewan' ? Icons.pets_outlined : Icons.eco_outlined,
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              _buildDropdownField(
                label: 'Status Konservasi',
                value: _selectedStatus,
                items: _statusOptions,
                icon: Icons.shield_outlined,
                onChanged: (value) => setState(() => _selectedStatus = value!),
                getItemColor: _getStatusColor,
              ),

              _buildSectionTitle('Detail Tambahan', Icons.notes_outlined),
              _buildTextField(
                controller: _habitatController,
                label: 'Habitat Utama',
                hint: 'Contoh: Hutan hujan tropis Sumatra',
                icon: Icons.forest_outlined,
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Deskripsi Lengkap',
                hint: 'Jelaskan ciri fisik, perilaku, dll.',
                icon: Icons.description_outlined,
                maxLines: 5,
              ),
              _buildTextField(
                controller: _funFactController,
                label: 'Fakta Menarik',
                hint: 'Satu fakta unik tentang spesies ini (opsional)',
                icon: Icons.lightbulb_outline,
                maxLines: 2,
                requiredField: false,
              ),

              _buildSectionTitle('Lokasi Penemuan (Opsional)', Icons.location_on_outlined),
               _buildTextField(
                controller: _latitudeController,
                label: 'Latitude',
                hint: 'Contoh: -6.200000',
                icon: Icons.gps_fixed_outlined,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                requiredField: false,
              ),
              _buildTextField(
                controller: _longitudeController,
                label: 'Longitude',
                hint: 'Contoh: 106.816666',
                icon: Icons.gps_not_fixed_outlined,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                requiredField: false,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isLoading ? Container() : const Icon(Icons.cloud_upload_outlined),
                  label: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Submit Data Spesies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}