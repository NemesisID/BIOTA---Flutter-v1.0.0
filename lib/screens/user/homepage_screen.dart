import 'package:flutter/material.dart';
import 'package:biota_2/services/auth_service.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/models/funfact.dart';
import 'package:biota_2/models/event.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/services/data_service.dart';
import 'package:biota_2/data/dummy_events.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/screens/user/event_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

class HomePageScreen extends StatefulWidget {
  final Function(int, Data?)? onTabChange;
  
  const HomePageScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> with WidgetsBindingObserver {
  String _userName = "";
  List<Data> _speciesData = [];
  String _selectedFilter = 'semua';
  bool _isLoadingSpecies = false;
  FunFact? _funFact;
  bool _isLoadingFunFact = false;
  Timer? _autoRefreshTimer;
  
  List<Event> _upcomingEvents = [];
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _loadSpeciesData();
    _loadFunFact();
    _loadEvents();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto refresh ketika app kembali ke foreground
      _loadSpeciesData();
      _loadFunFact();
      _loadEvents();
    }
  }

  // Auto refresh setiap 30 detik
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadSpeciesData();
        _loadFunFact();
        _loadEvents();
      }
    });
  }

  void _loadEvents() {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final allEvents = DummyEvents.getEvents();
      // Filter hanya upcoming events untuk homepage - TAMPILKAN SEMUA
      final upcomingEvents = allEvents.where((event) => event.isUpcoming).toList();
    
      setState(() {
        _upcomingEvents = upcomingEvents;
        _isLoadingEvents = false;
      });
    
      print('HomePage: Loaded ${upcomingEvents.length} upcoming events');
    } catch (e) {
      print('HomePage: Error loading events: $e');
      setState(() {
        _upcomingEvents = [];
        _isLoadingEvents = false;
      });
    }
  }

  void _showRegistrationDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.app_registration, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Konfirmasi Pendaftaran',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anda akan diarahkan ke formulir pendaftaran untuk event:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: 12),
              if (!event.isFree)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payment, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Biaya: Rp ${NumberFormat('#,###').format(event.price)}',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(event.registrationUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Lanjut Daftar',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
    );
  }

  // ✅ TAMBAH METHOD LAUNCH URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link pendaftaran')),
        );
      }
    }
  }

  // ✅ TAMBAH HELPER METHODS UNTUK EVENT
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hewan':
        return Icons.pets;
      case 'Tumbuhan':
        return Icons.eco;
      case 'Konservasi':
        return Icons.nature;
      case 'Edukasi':
        return Icons.school;
      case 'Penelitian':
        return Icons.science;
      case 'Aksi Lingkungan':
        return Icons.eco;
      case 'Seminar':
        return Icons.campaign;
      case 'Pelatihan':
        return Icons.fitness_center;
      case 'Festival':
        return Icons.celebration;
      case 'Kampanye':
        return Icons.volume_up;
      case 'Workshop':
        return Icons.build;
      default:
        return Icons.event;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Konservasi':
        return Colors.green;
      case 'Edukasi':
        return Colors.blue;
      case 'Penelitian':
        return Colors.purple;
      case 'Aksi Lingkungan':
        return Colors.teal;
      case 'Seminar':
        return Colors.orange;
      case 'Pelatihan':
        return Colors.red;
      case 'Festival':
        return Colors.pink;
      case 'Kampanye':
        return Colors.indigo;
      case 'Workshop':
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _loadUserName() async {
    User? user = await AuthService.getCurrentUser();
    String displayName = "User";
    if (user != null && user.fullName.isNotEmpty) {
      displayName = user.fullName.split(' ').first;
    }
    if (mounted) {
      setState(() {
        _userName = displayName;
      });
    }
  }

  Future<void> _loadSpeciesData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingSpecies = true;
    });

    try {
      print('HomePage: Loading approved species from database...');
      final DatabaseHelper databaseHelper = DatabaseHelper.instance;
      List<Data> approvedSpecies = await databaseHelper.getApprovedSpecies();
      
      print('HomePage: Found ${approvedSpecies.length} approved species');
      
      // Filter species yang memiliki koordinat (untuk konsistensi dengan explore screen)
      final speciesWithLocation = approvedSpecies
          .where((species) => 
            species.latitude != null && 
            species.longitude != null &&
            species.latitude != 0 &&
            species.longitude != 0)
          .toList();

      print('HomePage: ${speciesWithLocation.length} species have valid coordinates');

      if (mounted) {
        setState(() {
          _speciesData = speciesWithLocation;
          _isLoadingSpecies = false;
        });
      }
      
      if (_speciesData.isEmpty) {
        print('HomePage: No approved species with coordinates found');
      } else {
        print('HomePage: Successfully loaded species data');
        for (var species in _speciesData) {
          print('- ${species.speciesName} (${species.category}) at ${species.latitude}, ${species.longitude}');
        }
      }
    } catch (e) {
      print('HomePage: Error loading species data: $e');
      if (mounted) {
        setState(() {
          _speciesData = [];
          _isLoadingSpecies = false;
        });
      }
    }
  }

  Future<void> _loadFunFact() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingFunFact = true;
    });

    try {
      final DatabaseHelper databaseHelper = DatabaseHelper.instance;
      final funFactData = await databaseHelper.getFunFact();
      
      if (mounted) {
        if (funFactData != null) {
          setState(() {
            _funFact = FunFact.fromMap(funFactData);
            _isLoadingFunFact = false;
          });
        } else {
          setState(() {
            _isLoadingFunFact = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFunFact = false;
        });
      }
      print('Error loading fun fact: $e');
    }
  }

  List<Data> get _filteredSpeciesData {
    switch (_selectedFilter) {
      case 'hewan':
        return _speciesData.where((species) => species.category.toLowerCase() == 'hewan').toList();
      case 'tumbuhan':
        return _speciesData.where((species) => species.category.toLowerCase() == 'tumbuhan').toList();
      default:
        return _speciesData;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'banyak':
        return Colors.green;
      case 'rentan':
        return Colors.orange;
      case 'terancam punah':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToSpeciesOnMap(Data species) {
    // Navigasi ke explore tab dengan species yang dipilih
    if (widget.onTabChange != null) {
      widget.onTabChange!(1, species); // Index 1 untuk explore tab
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'leaf':
        return Icons.eco;
      case 'animal':
        return Icons.pets;
      case 'tree':
        return Icons.park;
      case 'earth':
        return Icons.public;
      case 'recycle':
        return Icons.recycling;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'celebration':
        return Icons.celebration;
      case 'nature':
        return Icons.nature;
      case 'eco':
        return Icons.eco;
      case 'forest':
        return Icons.forest;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.water_drop;
    }
  }

  Color _getBackgroundColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue[300]!;
      case 'green':
        return Colors.green[300]!;
      case 'orange':
        return Colors.orange[300]!;
      case 'purple':
        return Colors.purple[300]!;
      case 'teal':
        return Colors.teal[300]!;
      case 'indigo':
        return Colors.indigo[300]!;
      case 'pink':
        return Colors.pink[300]!;
      default:
        return Colors.blue[300]!;
    }
  }

  Color _getCardBackgroundFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue[50]!;
      case 'green':
        return Colors.green[50]!;
      case 'orange':
        return Colors.orange[50]!;
      case 'purple':
        return Colors.purple[50]!;
      case 'teal':
        return Colors.teal[50]!;
      case 'indigo':
        return Colors.indigo[50]!;
      case 'pink':
        return Colors.pink[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/logo.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'BIOTA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSpeciesData();
          await _loadFunFact();
          _loadEvents(); // ✅ TAMBAH REFRESH EVENTS
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salam User
              _buildWelcomeSection(),
              const SizedBox(height: 20),

              // Berita Alam Hari Ini
              _buildNewsSection(),
              const SizedBox(height: 20),

              // Berita Ceria
              _buildGoodNewsSection(),
              const SizedBox(height: 20),

              // Keanekaragaman Hayati - DENGAN DATA REAL
              _buildBiodiversitySection(),
              const SizedBox(height: 20),

              // Event Volunteer - ✅ GUNAKAN DATA REAL
              _buildEventSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $_userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Jelajahi & Lindungi Flora & Fauna di Sekitarmu',
          style: TextStyle(
            fontSize: 14, 
            color: Colors.grey[600]
          ),
        ),
      ],
    );
  }

  // ✅ OPTIONAL: TINGKATKAN HEIGHT CONTAINER JIKA PERLU
  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Berita Alam Hari Ini!',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210, // ✅ SET HEIGHT YANG SAMA DENGAN CARD HEIGHT
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildNewsCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(int index) {
  List<Map<String, String>> newsData = [
    {
      'title': 'KETIKA HUTAN BICARA: MEMBANGUN KEPERCAYAAN UNTUK SELAMATKAN GAJAH SUMATRA',
      'source': 'WWF Indonesia',
      'time': '2 jam yang lalu',
      'category': 'Konservasi',
      'image': 'https://www.wwf.id/sites/default/files/blog/_WW1327381%20%281%29_0.jpg?ixlib=rb-4.0.3&w=800&q=80',
      'url': 'https://www.wwf.id/id/blog/ketika-hutan-bicara-membangun-kepercayaan-untuk-selamatkan-gajah-sumatra',
    },
    {
      'title': 'RUANG KELOLA EKOWISATA DI DALAM WILAYAH ADAT ROBY DIGAN',
      'source': 'WWF Indonesia',
      'time': '4 jam yang lalu',
      'category': 'Konservasi',
      'image': 'https://www.wwf.id/sites/default/files/blog/DSC_3999.JPG?ixlib=rb-4.0.3&w=800&q=80',
      'url': 'https://www.wwf.id/id/blog/ruang-kelola-ekowisata-di-dalam-wilayah-adat-roby-digan',
    },
    {
      'title': 'Terobosan Alat Skrining Genetik Beri Harapan Baru untuk Konservasi Koala',
      'source': 'National Geographic Indonesia',
      'time': '6 jam yang lalu',
      'category': 'Inovasi',
      'image': 'https://cdn.grid.id/crop/0x0:0x0/700x465/photo/2025/06/14/koalajpg-20250614010728.jpg?ixlib=rb-4.0.3&w=800&q=80',
      'url': 'https://nationalgeographic.grid.id/read/134262086/terobosan-alat-skrining-genetik-beri-harapan-baru-untuk-konservasi-koala',
    },
    {
      'title': '#SayaPilihBumi melakukan City Clean Up dan Talkshow dengan Komunitas Peduli Lingkungan',
      'source': 'Kompas Lingkungan',
      'time': '8 jam yang lalu',
      'category': 'Aksi Komunitas',
      'image': 'https://cdn.grid.id/crop/0x0:0x0/700x465/photo/2024/06/10/spbjpg-20240610033731.jpg?ixlib=rb-4.0.3&w=800&q=80',
      'url': 'https://nationalgeographic.grid.id/read/134103258/sayapilihbumi-melakukan-city-clean-up-dan-talkshow-dengan-komunitas-peduli-lingkungan',
    },
    {
      'title': 'Terancam Punah, Orang Utan Tapanuli di Batang Toru Butuh Koridor Satwa Liar',
      'source': 'National Geographic Indonesia',
      'time': '12 jam yang lalu',
      'category': 'Awareness',
      'image': 'https://cdn.grid.id/crop/0x0:0x0/700x465/photo/2018/08/13/1744483748.jpg?ixlib=rb-4.0.3&w=800&q=80',
      'url': 'https://nationalgeographic.grid.id/read/134260964/terancam-punah-orang-utan-tapanuli-di-batang-toru-butuh-koridor-satwa-liar',
    },
  ];

  // ✅ AMBIL DATA BERDASARKAN INDEX
  String newsTitle = newsData[index]['title']!;
  String newsSource = newsData[index]['source']!;
  String newsTime = newsData[index]['time']!;
  String newsCategory = newsData[index]['category']!;
  String imageUrl = newsData[index]['image']!;
  String websiteUrl = newsData[index]['url']!; // ✅ TAMBAH URL WEBSITE

  // ✅ WARNA KATEGORI YANG BERBEDA
  Color getCategoryColor(String category) {
    switch (category) {
      case 'Konservasi':
        return Colors.green;
      case 'Penemuan':
        return Colors.blue;
      case 'Restorasi':
        return Colors.teal;
      case 'Aksi Komunitas':
        return Colors.orange;
      case 'Teknologi':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  // ✅ ICON KATEGORI YANG BERBEDA
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Konservasi':
        return Icons.nature_people;
      case 'Penemuan':
        return Icons.explore;
      case 'Restorasi':
        return Icons.restore;
      case 'Aksi Komunitas':
        return Icons.groups;
      case 'Teknologi':
        return Icons.memory;
      default:
        return Icons.article;
    }
  }

  return Card(
    elevation: 3,
    margin: const EdgeInsets.only(right: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Container(
      width: 250,
      height: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ IMAGE SECTION DENGAN GAMBAR REAL
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 90,
              width: double.infinity,
              child: Stack(
                children: [
                  // ✅ NETWORK IMAGE SEBAGAI BACKGROUND
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            getCategoryColor(newsCategory).withOpacity(0.7),
                            getCategoryColor(newsCategory).withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.8),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            getCategoryColor(newsCategory).withOpacity(0.7),
                            getCategoryColor(newsCategory).withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          getCategoryIcon(newsCategory),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  
                  // ✅ OVERLAY GRADIENT UNTUK READABILITY
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // ✅ CATEGORY BADGE DI POJOK KIRI ATAS
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: getCategoryColor(newsCategory),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getCategoryIcon(newsCategory),
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            newsCategory,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Section
                  Text(
                    newsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Source & Time Section dengan warna berbeda
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: getCategoryColor(newsCategory).withOpacity(0.2),
                        child: Text(
                          newsSource[0], // First letter of source
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            color: getCategoryColor(newsCategory),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$newsSource • $newsTime',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600]
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // ✅ BUTTON SECTION DENGAN LAUNCH URL
                  Container(
                    height: 36,
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // ✅ LAUNCH WEBSITE URL
                        await _launchNewsUrl(websiteUrl, newsTitle);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 4
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: getCategoryColor(newsCategory),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Baca',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new, // ✅ GANTI ICON KE EXTERNAL LINK
                            size: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
  );
  }

  // ✅ PERBAIKI METHOD LAUNCH URL - SAMA PERSIS DENGAN EVENT
  Future<void> _launchNewsUrl(String url, String title) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link berita')),
      );
    }
  }
}

  Widget _buildGoodNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Berita Ceria Hari Ini',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _isLoadingFunFact
            ? Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _funFact != null
                ? Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: _getCardBackgroundFromString(_funFact!.backgroundColor),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _getBackgroundColorFromString(_funFact!.backgroundColor),
                            child: Icon(
                              _getIconFromString(_funFact!.icon),
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _funFact!.title,
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _funFact!.description,
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[700]
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  )
                : Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada berita ceria',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildBiodiversitySection() {
    final filteredData = _filteredSpeciesData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keanekaragaman Hayati',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Kenali flora & fauna di sekitar kita',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate ke explore tab tanpa focus species
                if (widget.onTabChange != null) {
                  widget.onTabChange!(1, null);
                }
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primary),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),

        // Filter Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('Semua', 'semua'),
              const SizedBox(width: 8),
              _buildFilterButton('Hewan', 'hewan'),
              const SizedBox(width: 8),
              _buildFilterButton('Tumbuhan', 'tumbuhan'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Species Cards Grid atau Empty State
        _isLoadingSpecies
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : filteredData.isNotEmpty
                ? SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        return _buildSpeciesCard(filteredData[index]);
                      },
                    ),
                  )
                : _buildEmptySpeciesState(),
      ],
    );
  }

  Widget _buildFilterButton(String text, String value) {
    final isSelected = _selectedFilter == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        elevation: isSelected ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.primary, 
            width: isSelected ? 0 : 1
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSpeciesCard(Data species) {
    Color statusColor = _getStatusColor(species.status);
    IconData categoryIcon = _getCategoryIcon(species.category);

    return GestureDetector(
      onTap: () => _navigateToSpeciesOnMap(species),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Species Image
              Container(
                height: 110, // ✅ KURANGI TINGGI GAMBAR DARI 120 MENJADI 110
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSpeciesImage(species, categoryIcon, statusColor),
                ),
              ),
              const SizedBox(height: 8), // ✅ KURANGI SPASI DARI 12 MENJADI 8

              // Header dengan kategori icon dan status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      species.status,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Species Info
              Text(
                species.speciesName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                species.latinName,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // ✅ KURANGI SPASI DARI 8 MENJADI 6

              // Category and Location
              Row(
                children: [
                  Icon(
                    categoryIcon,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      species.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      species.habitat,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // ✅ KURANGI SPASI DARI 12 MENJADI 8

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToSpeciesOnMap(species),
                  icon: const Icon(Icons.map, size: 14),
                  label: const Text(
                    'Lihat di Peta',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
        ),
      )
    );
  }

  // Image builder yang sudah disesuaikan dengan data real
  Widget _buildSpeciesImage(Data species, IconData categoryIcon, Color statusColor) {
    // Jika ada path gambar di database
    if (species.image != null && species.image!.isNotEmpty) {
      final imagePath = species.image!;
      
      // Network URL (untuk data dari form atau API)
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(categoryIcon, statusColor);
          },
        );
      }
      // File path (untuk data dari form yang upload local)
      else if (File(imagePath).existsSync()) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(categoryIcon, statusColor);
          },
        );
      }
    }
    
    // Fallback ke default image jika tidak ada gambar
    return _buildDefaultImage(categoryIcon, statusColor);
  }

  Widget _buildDefaultImage(IconData categoryIcon, Color statusColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
      ),
      child: Icon(
        categoryIcon,
        size: 40,
        color: statusColor,
      ),
    );
  }

  // ✅ UPDATE EVENT SECTION DENGAN DATA REAL
  Widget _buildEventSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Alam',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Siap untuk petualangan konservasi minggu ini?',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Navigate ke event tab
                if (widget.onTabChange != null) {
                  widget.onTabChange!(2, null); // Index 2 untuk event tab
                }
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primary),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        
        // Event Cards dengan data real
        _isLoadingEvents
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _upcomingEvents.isNotEmpty
                ? SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _upcomingEvents.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(_upcomingEvents[index]);
                      },
                    ),
                  )
                : _buildEmptyEventState(),
      ],
    );
  }

  // ✅ BUAT EVENT CARD DENGAN DATA REAL
  Widget _buildEventCard(Event event) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Navigate ke event detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Network Image
                      CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getCategoryColor(event.category).withOpacity(0.3),
                                _getCategoryColor(event.category).withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white.withOpacity(0.8),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getCategoryColor(event.category).withOpacity(0.3),
                                _getCategoryColor(event.category).withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(event.category),
                              size: 40,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      // Status Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Event Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Price
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(event.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(event.category),
                                  size: 10,
                                  color: _getCategoryColor(event.category),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.category,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _getCategoryColor(event.category),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: event.isFree ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.isFree ? 'GRATIS' : 'Rp ${NumberFormat('#,###').format(event.price)}',
                              style: TextStyle(
                                color: event.isFree ? Colors.green : AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(event.startDate),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Participants & Register Button
                      Row(
                        children: [
                          Icon(Icons.group, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${event.currentParticipants}/${event.maxParticipants}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          if (event.isRegistrationOpen)
                            ElevatedButton(
                              onPressed: () => _showRegistrationDialog(context, event),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Daftar',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  // ✅ HAPUS DEAD CODE DAN PERBAIKI EMPTY EVENT STATE
  Widget _buildEmptyEventState() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.event_busy,
              size: 36,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Belum Ada Event Mendatang',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Event konservasi akan ditampilkan di sini. Pantau terus untuk kegiatan seru!',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          OutlinedButton.icon(
            onPressed: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(2, null); // Navigate ke event tab
              }
            },
            icon: const Icon(Icons.explore, size: 14),
            label: const Text(
              'Lihat Semua Event',
              style: TextStyle(fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ PERBAIKI EMPTY SPECIES STATE - HAPUS DUPLIKASI
  Widget _buildEmptySpeciesState() {
    String message = '';
    String description = '';
    IconData icon = Icons.nature_people;
    
    switch (_selectedFilter) {
      case 'hewan':
        message = 'Belum Ada Informasi Hewan';
        description = 'Saat ini belum ada data hewan yang tersedia. Informasi hewan akan ditampilkan di sini setelah ada data yang disetujui.';
        icon = Icons.pets;
        break;
      case 'tumbuhan':
        message = 'Belum Ada Informasi Tumbuhan';
        description = 'Saat ini belum ada data tumbuhan yang tersedia. Informasi tumbuhan akan ditampilkan di sini setelah ada data yang disetujui.';
        icon = Icons.eco;
        break;
      default:
        message = 'Belum Ada Informasi Spesies';
        description = 'Saat ini belum ada informasi spesies yang tersedia. Data flora dan fauna akan ditampilkan di sini setelah ada kontribusi yang disetujui.';
        icon = Icons.nature_people;
        break;
    }

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1, null);
                  }
                },
                icon: const Icon(Icons.explore, size: 16),
                label: const Text(
                  'Jelajahi',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}