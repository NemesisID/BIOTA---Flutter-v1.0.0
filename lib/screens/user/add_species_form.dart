import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/data.dart';
import '../../services/database_helper.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../models/user.dart';

class AddSpeciesForm extends StatefulWidget {
  const AddSpeciesForm({super.key});

  @override
  State<AddSpeciesForm> createState() => _AddSpeciesFormState();
}

class _AddSpeciesFormState extends State<AddSpeciesForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _speciesNameController = TextEditingController();
  final _latinNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _habitatController = TextEditingController();

  // Form state
  String _selectedType = 'Hewan';
  String _selectedStatus = 'Banyak';
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  User? _currentUser;
  Position? _currentPosition;

  // Options
  final List<String> _typeOptions = ['Hewan', 'Tumbuhan'];
  final List<String> _statusOptions = [
    'Banyak',
    'Rentan', 
    'Terancam Punah'
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
    _descriptionController.dispose();
    _locationController.dispose();
    _habitatController.dispose();
    super.dispose();
  }

  // Fungsi untuk mendapatkan lokasi saat ini
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Cek permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin akses lokasi ditolak secara permanen. Aktifkan di pengaturan aplikasi.');
      }

      // Dapatkan posisi saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Konversi koordinat ke alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        if (address.isEmpty) {
          address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        }

        setState(() {
          _currentPosition = position;
          _locationController.text = address;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil didapatkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
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
    switch (status) {
      case 'Tidak Rentan': return Colors.green.shade600;
      case 'Rentan': return Colors.orange.shade600;
      case 'Terancam Punah': return Colors.red.shade600;
      default: return Colors.grey.shade600;
    }
  }

  String _convertStatusToDatabase(String displayStatus) {
    switch (displayStatus) {
      case 'Tidak Rentan': return 'Aman';
      case 'Rentan': return 'Rentan';
      case 'Terancam Punah': return 'Terancam Punah';
      default: return 'Aman';
    }
  }

  Future<void> _submitForm() async {
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

      final data = Data(
        image: imagePath,
        speciesName: _speciesNameController.text.trim(),
        latinName: _latinNameController.text.trim(),
        category: _selectedType,
        habitat: _habitatController.text.trim(),
        status: _convertStatusToDatabase(_selectedStatus),
        description: _descriptionController.text.trim(),
        funFact: null,
        userId: _currentUser!.id,
        isApproved: 0,
        createdAt: DateTime.now().toIso8601String(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      await DatabaseHelper.instance.insertData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disubmit! Menunggu persetujuan admin.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        _speciesNameController.clear();
        _latinNameController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _habitatController.clear();
        setState(() {
          _selectedImage = null;
          _selectedType = 'Hewan';
          _selectedStatus = 'Tidak Rentan';
          _currentPosition = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tambah Data Spesies',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data yang Anda kirim akan ditinjau oleh Admin sebelum dipublikasikan.',
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section 1: Identitas Utama
              _buildSectionHeader('1. Identitas Utama', Icons.fingerprint),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _speciesNameController,
                label: 'Nama Spesies',
                hint: 'Contoh: Harimau Sumatra',
                icon: Icons.pets,
                required: true,
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _latinNameController,
                label: 'Nama Latin Spesies',
                hint: 'Contoh: Panthera tigris sumatrae',
                icon: Icons.science,
                required: true,
              ),
              
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Jenis',
                value: _selectedType,
                items: _typeOptions,
                icon: _selectedType == 'Hewan' ? Icons.pets : Icons.eco,
                onChanged: (value) => setState(() => _selectedType = value!),
              ),

              const SizedBox(height: 32),

              // Section 2: Detail & Status Konservasi
              _buildSectionHeader('2. Detail & Status Konservasi', Icons.shield),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Status Konservasi',
                value: _selectedStatus,
                items: _statusOptions,
                icon: Icons.security,
                onChanged: (value) => setState(() => _selectedStatus = value!),
                showStatusColor: true,
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Deskripsi Singkat',
                hint: 'Jelaskan ciri fisik, perilaku, atau karakteristik utama',
                icon: Icons.description,
                maxLines: 4,
                required: true,
              ),

              const SizedBox(height: 32),

              // Section 3: Lokasi & Media
              _buildSectionHeader('3. Lokasi & Media', Icons.location_on),
              const SizedBox(height: 16),
              
              _buildImagePicker(),
              
              const SizedBox(height: 16),
              
              _buildLocationField(),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _habitatController,
                label: 'Habitat',
                hint: 'Contoh: Hutan hujan tropis dataran rendah',
                icon: Icons.forest,
                required: true,
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading 
                    ? const SizedBox.shrink()
                    : const Icon(Icons.cloud_upload, size: 20),
                  label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Data Spesies',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      } : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    bool showStatusColor = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              if (showStatusColor)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(item),
                    shape: BoxShape.circle,
                  ),
                ),
              if (showStatusColor) const SizedBox(width: 8),
              Text(item),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.place, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
            const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' (Opsional)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Tekan tombol GPS untuk mendapatkan lokasi saat ini',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 2,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.gps_fixed,
                        color: Colors.white,
                        size: 24,
                      ),
                tooltip: 'Dapatkan lokasi saat ini',
              ),
            ),
          ],
        ),
        if (_currentPosition != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
            const Text(
              'Gambar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' (Opsional)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              color: Colors.grey.shade50,
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketuk untuk memilih gambar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG (Maks. 5MB)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}