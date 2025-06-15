import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/models/event.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/data/dummy_events.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Event> upcomingEvents = [];
  List<Event> ongoingEvents = [];
  List<Event> completedEvents = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    setState(() => isLoading = true);
    
    try {
      print('=== LOADING EVENT DATA ===');
      
      final allEvents = DummyEvents.getEvents();
      
      print('Total events loaded: ${allEvents.length}');
      
      setState(() {
        upcomingEvents = allEvents.where((event) => event.isUpcoming).toList();
        ongoingEvents = allEvents.where((event) => event.isOngoing).toList();
        completedEvents = allEvents.where((event) => event.isPast).toList();
        isLoading = false;
      });
      
      print('=== EVENT FILTERING RESULTS ===');
      print('Upcoming: ${upcomingEvents.length}');
      print('Ongoing: ${ongoingEvents.length}');
      print('Completed: ${completedEvents.length}');
      
    } catch (e) {
      print('Error loading events: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ METHOD _showEventDialog - PASTIKAN INI ADA
  Future<void> _showEventDialog({Event? event}) async {
    final isEditing = event != null;
    
    // Controllers untuk form
    final titleController = TextEditingController(text: event?.title ?? '');
    final shortDescriptionController = TextEditingController(text: event?.shortDescription ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    final organizerController = TextEditingController(text: event?.organizer ?? '');
    final imageUrlController = TextEditingController(text: event?.imageUrl ?? '');
    final registrationUrlController = TextEditingController(text: event?.registrationUrl ?? '');
    final requirementsController = TextEditingController(text: event?.requirements ?? '');
    final contactInfoController = TextEditingController(text: event?.contactInfo ?? '');
    final maxParticipantsController = TextEditingController(
      text: event?.maxParticipants.toString() ?? '50'
    );
    final priceController = TextEditingController(
      text: event?.price?.toString() ?? '0'
    );
    
    // Date/Time variables
    DateTime selectedStartDate = event?.startDate ?? DateTime.now().add(const Duration(days: 1));
    DateTime selectedEndDate = event?.endDate ?? DateTime.now().add(const Duration(days: 1, hours: 2));
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(selectedStartDate);
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(selectedEndDate);
    
    String selectedCategory = event?.category ?? 'Konservasi';
    bool isFree = event?.isFree ?? true;
    String currentImageUrl = event?.imageUrl ?? '';
    
    final categories = [
      'Konservasi', 
      'Edukasi', 
      'Penelitian', 
      'Aksi Lingkungan', 
      'Seminar', 
      'Pelatihan', 
      'Festival', 
      'Kampanye', 
      'Workshop'
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Event' : 'Tambah Event Baru',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview Section
                  if (currentImageUrl.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🖼️ Preview Gambar',
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.primary
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          currentImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, 
                                    size: 48, 
                                    color: Colors.grey[400]
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak dapat dimuat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Basic Information Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📝 Informasi Dasar',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Event *',
                      hintText: 'Contoh: Penanaman Mangrove Bersama',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Short Description
                  TextField(
                    controller: shortDescriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Singkat *',
                      hintText: 'Deskripsi singkat yang menarik untuk preview',
                      prefixIcon: const Icon(Icons.short_text),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Full Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Lengkap *',
                      hintText: 'Penjelasan detail tentang event',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Location & Organizer Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📍 Lokasi & Penyelenggara',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi *',
                      hintText: 'Contoh: Pantai Mangrove, Jakarta Utara',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Organizer
                  TextField(
                    controller: organizerController,
                    decoration: InputDecoration(
                      labelText: 'Penyelenggara *',
                      hintText: 'Contoh: BIOTA Community',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date & Time Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⏰ Waktu Pelaksanaan',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedStartDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Tanggal Mulai *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy').format(selectedStartDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedStartTime,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedStartTime = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Jam Mulai *',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(selectedStartTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // End Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedEndDate,
                              firstDate: selectedStartDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedEndDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Tanggal Selesai *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy').format(selectedEndDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedEndTime,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedEndTime = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Jam Selesai *',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(selectedEndTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Participants & Price Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '👥 Peserta & Harga',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Max Participants
                  TextField(
                    controller: maxParticipantsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Maksimal Peserta *',
                      hintText: '50',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Free Event Switch
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Event Gratis')),
                        Switch(
                          value: isFree,
                          onChanged: (value) {
                            setDialogState(() => isFree = value);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  
                  // Price Field (if not free)
                  if (!isFree) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp) *',
                        hintText: '50000',
                        prefixIcon: const Icon(Icons.payment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Additional Information Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📋 Informasi Tambahan',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Requirements
                  TextField(
                    controller: requirementsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Persyaratan',
                      hintText: 'Contoh: Membawa botol minum, pakai baju yang nyaman',
                      prefixIcon: const Icon(Icons.rule),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Info
                  TextField(
                    controller: contactInfoController,
                    decoration: InputDecoration(
                      labelText: 'Informasi Kontak *',
                      hintText: 'WhatsApp: 08123456789 atau email@biota.com',
                      prefixIcon: const Icon(Icons.contact_phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image URL with Preview
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL Gambar',
                      hintText: 'https://example.com/image.jpg',
                      prefixIcon: const Icon(Icons.image),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.preview),
                        onPressed: () {
                          if (imageUrlController.text.trim().isNotEmpty) {
                            setDialogState(() {
                              currentImageUrl = imageUrlController.text.trim();
                            });
                          }
                        },
                        tooltip: 'Preview Gambar',
                      ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (value.trim().isNotEmpty && value == imageUrlController.text) {
                          setDialogState(() {
                            currentImageUrl = value.trim();
                          });
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Registration URL
                  TextField(
                    controller: registrationUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL Pendaftaran',
                      hintText: 'https://forms.google.com/...',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    '* Field wajib diisi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
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
                if (_validateEventForm(
                  titleController.text,
                  shortDescriptionController.text,
                  descriptionController.text,
                  locationController.text,
                  organizerController.text,
                  contactInfoController.text,
                  maxParticipantsController.text,
                  isFree,
                  priceController.text,
                )) {
                  await _saveEvent(
                    event: event,
                    title: titleController.text,
                    shortDescription: shortDescriptionController.text,
                    description: descriptionController.text,
                    location: locationController.text,
                    organizer: organizerController.text,
                    category: selectedCategory,
                    startDate: selectedStartDate,
                    endDate: selectedEndDate,
                    startTime: selectedStartTime,
                    endTime: selectedEndTime,
                    maxParticipants: int.tryParse(maxParticipantsController.text) ?? 50,
                    isFree: isFree,
                    price: !isFree ? double.tryParse(priceController.text) : null,
                    requirements: requirementsController.text,
                    contactInfo: contactInfoController.text,
                    imageUrl: imageUrlController.text,
                    registrationUrl: registrationUrlController.text,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update Event' : 'Simpan Event'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateEventForm(String title, String shortDescription, String description, 
                          String location, String organizer, String contactInfo,
                          String maxParticipants, bool isFree, String price) {
    if (title.trim().isEmpty) {
      _showErrorSnackBar('Judul event harus diisi');
      return false;
    }
    if (shortDescription.trim().isEmpty) {
      _showErrorSnackBar('Deskripsi singkat harus diisi');
      return false;
    }
    if (description.trim().isEmpty) {
      _showErrorSnackBar('Deskripsi lengkap harus diisi');
      return false;
    }
    if (location.trim().isEmpty) {
      _showErrorSnackBar('Lokasi event harus diisi');
      return false;
    }
    if (organizer.trim().isEmpty) {
      _showErrorSnackBar('Penyelenggara harus diisi');
      return false;
    }
    if (contactInfo.trim().isEmpty) {
      _showErrorSnackBar('Informasi kontak harus diisi');
      return false;
    }
    if (maxParticipants.trim().isEmpty || int.tryParse(maxParticipants) == null || int.parse(maxParticipants) <= 0) {
      _showErrorSnackBar('Maksimal peserta harus berupa angka positif');
      return false;
    }
    if (!isFree && (price.trim().isEmpty || double.tryParse(price) == null || double.parse(price) <= 0)) {
      _showErrorSnackBar('Harga harus berupa angka positif jika event berbayar');
      return false;
    }
    return true;
  }

  Future<void> _saveEvent({
    Event? event,
    required String title,
    required String shortDescription,
    required String description,
    required String location,
    required String organizer,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int maxParticipants,
    required bool isFree,
    double? price,
    required String requirements,
    required String contactInfo,
    required String imageUrl,
    required String registrationUrl,
  }) async {
    try {
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute,
      );
      
      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endTime.hour,
        endTime.minute,
      );

      print('=== EVENT DATA TO SAVE ===');
      print('Title: $title');
      print('Category: $category');
      print('Location: $location');
      print('Organizer: $organizer');
      print('Start: $startDateTime');
      print('End: $endDateTime');
      print('Max Participants: $maxParticipants');
      print('Is Free: $isFree');
      print('Price: $price');
      print('Image URL: $imageUrl');
      print('========================');

      if (event == null) {
        _showSuccessSnackBar('✅ Event baru berhasil ditambahkan (Demo Mode)');
      } else {
        _showSuccessSnackBar('✅ Event berhasil diupdate (Demo Mode)');
      }

      await _loadEventData();
    } catch (e) {
      print('Error saving event: $e');
      _showErrorSnackBar('❌ Error: ${e.toString()}');
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await _showConfirmDialog(
      'Hapus Event',
      'Apakah Anda yakin ingin menghapus event "${event.title}"?\n\nTindakan ini tidak dapat dibatalkan!',
      'Hapus',
      Colors.red,
    );

    if (confirm) {
      try {
        print('=== DELETING EVENT ===');
        print('Event ID: ${event.id}');
        print('Event Title: ${event.title}');
        
        _showSuccessSnackBar('✅ Event "${event.title}" berhasil dihapus (Demo Mode)');
        await _loadEventData();
      } catch (e) {
        print('Error deleting event: $e');
        _showErrorSnackBar('❌ Error: ${e.toString()}');
      }
    }
  }

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
            Expanded(child: Text(title)),
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

  List<Event> _getFilteredEvents(List<Event> events) {
    if (searchQuery.isEmpty) return events;

    return events.where((event) {
      final searchLower = searchQuery.toLowerCase();
      return event.title.toLowerCase().contains(searchLower) ||
             event.description.toLowerCase().contains(searchLower) ||
             event.location.toLowerCase().contains(searchLower) ||
             event.category.toLowerCase().contains(searchLower) ||
             event.organizer.toLowerCase().contains(searchLower);
    }).toList();
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(), // ✅ PANGGILAN METHOD INI HARUS BEKERJA
        icon: const Icon(Icons.add),
        label: const Text('Tambah Event'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari event berdasarkan judul, lokasi, kategori...',
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upcoming, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        'Akan Datang\n(${upcomingEvents.length})',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        'Berlangsung\n(${ongoingEvents.length})',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        'Selesai\n(${completedEvents.length})',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
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
                        Text('Memuat data event...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventsList(_getFilteredEvents(upcomingEvents), 'upcoming'),
                      _buildEventsList(_getFilteredEvents(ongoingEvents), 'ongoing'),
                      _buildEventsList(_getFilteredEvents(completedEvents), 'completed'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events, String type) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming' ? Icons.event_note :
              type == 'ongoing' ? Icons.play_circle_outline :
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming' ? 'Tidak ada event yang akan datang' :
              type == 'ongoing' ? 'Tidak ada event yang sedang berlangsung' :
              'Tidak ada event yang telah selesai',
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
              'Tap tombol "Tambah Event" untuk membuat event baru',
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadEventData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event, type);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event, String type) {
    final canEdit = type == 'upcoming';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          if (event.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 160,
                child: Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, 
                            size: 40, 
                            color: Colors.grey[400]
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gambar tidak dapat dimuat',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getCategoryIcon(event.category), color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            event.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.statusText,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Event Details
                _buildDetailRow(Icons.location_on, 'Lokasi', event.location),
                const SizedBox(height: 4),
                _buildDetailRow(Icons.business, 'Penyelenggara', event.organizer),
                const SizedBox(height: 4),
                _buildDetailRow(Icons.access_time, 'Mulai', DateFormat('dd/MM/yyyy HH:mm').format(event.startDate)),
                const SizedBox(height: 4),
                _buildDetailRow(Icons.event_available, 'Selesai', DateFormat('dd/MM/yyyy HH:mm').format(event.endDate)),
                const SizedBox(height: 4),
                _buildDetailRow(
                  Icons.people, 
                  'Peserta', 
                  '${event.currentParticipants}/${event.maxParticipants}'
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  Icons.payment, 
                  'Harga', 
                  event.isFree ? 'Gratis' : 'Rp ${NumberFormat('#,###').format(event.price)}'
                ),
                
                if (event.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.shortDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEventDetail(event),
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text(
                          'Detail',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    
                    if (canEdit) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEventDialog(event: event), // ✅ PANGGILAN METHOD INI JUGA HARUS BEKERJA
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteEvent(event),
                        icon: const Icon(Icons.delete, size: 14),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetail(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getCategoryIcon(event.category), color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    event.category,
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
                // Image Preview in Detail
                if (event.imageUrl.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, 
                                  size: 48, 
                                  color: Colors.grey[400]
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gambar tidak dapat dimuat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Event Details
                _buildDetailRow(Icons.business, 'Penyelenggara', event.organizer),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on, 'Lokasi', event.location),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.access_time, 'Mulai', DateFormat('EEEE, dd MMMM yyyy HH:mm').format(event.startDate)),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.event_available, 'Selesai', DateFormat('EEEE, dd MMMM yyyy HH:mm').format(event.endDate)),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.schedule, 'Durasi', '${event.endDate.difference(event.startDate).inHours} jam'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.people, 'Kapasitas', '${event.currentParticipants}/${event.maxParticipants} peserta'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.payment, 'Harga', event.isFree ? 'Gratis' : 'Rp ${NumberFormat('#,###').format(event.price)}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.app_registration, 'Pendaftaran', event.isRegistrationOpen ? 'Terbuka' : 'Tertutup'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.contact_phone, 'Kontak', event.contactInfo),
                
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Deskripsi:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                  ),
                ],
                
                if (event.requirements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Persyaratan:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.requirements,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                  ),
                ],
                
                if (event.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tags:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: event.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
                
                // Registration Link
                if (event.registrationUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Link Pendaftaran:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.registrationUrl,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'konservasi':
        return Icons.nature;
      case 'edukasi':
        return Icons.school;
      case 'penelitian':
        return Icons.science;
      case 'aksi lingkungan':
        return Icons.eco;
      case 'seminar':
        return Icons.campaign;
      case 'pelatihan':
        return Icons.fitness_center;
      case 'festival':
        return Icons.celebration;
      case 'kampanye':
        return Icons.volume_up;
      case 'workshop':
        return Icons.build;
      default:
        return Icons.event;
    }
  }
}