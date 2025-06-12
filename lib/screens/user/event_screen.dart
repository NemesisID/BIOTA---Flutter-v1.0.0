import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/event.dart';
import 'package:biota_2/data/dummy_events.dart';
import 'package:biota_2/screens/user/event_detail_screen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _allEvents = DummyEvents.getEvents();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Event> filtered = _allEvents;

    // Filter by search query only
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) =>
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.organizer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    setState(() {
      _filteredEvents = filtered;
    });
  }

  List<Event> _getEventsByStatus(String status) {
    switch (status) {
      case 'upcoming':
        return _filteredEvents.where((event) => event.isUpcoming).toList();
      case 'ongoing':
        return _filteredEvents.where((event) => event.isOngoing).toList();
      case 'past':
        return _filteredEvents.where((event) => event.isPast).toList();
      default:
        return _filteredEvents;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar langsung di atas
            _buildSearchBar(),
            // Tab Bar untuk status event
            _buildTabBar(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_getEventsByStatus('upcoming')),
                  _buildEventList(_getEventsByStatus('ongoing')),
                  _buildEventList(_getEventsByStatus('past')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari event konservasi, lokasi, atau penyelenggara...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11, // Kurangi ukuran font
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11, // Kurangi ukuran font
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Indicator mengikuti ukuran tab
        tabs: [
          // Tab 1: Akan Datang
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 14),
                const SizedBox(height: 2),
                const Text(
                  'Akan Datang',
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tab 2: Berlangsung
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle, size: 14),
                const SizedBox(height: 2),
                const Text(
                  'Berlangsung',
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tab 3: Selesai
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 14),
                const SizedBox(height: 2),
                const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      String message = '';
      String submessage = '';
      IconData iconData = Icons.event_busy;
      
      if (_searchQuery.isNotEmpty) {
        message = 'Event tidak ditemukan';
        submessage = 'Coba ubah kata kunci pencarian';
        iconData = Icons.search_off;
      } else {
        int currentTab = _tabController.index;
        switch (currentTab) {
          case 0:
            message = 'Tidak ada event yang akan datang';
            submessage = 'Event mendatang akan muncul di sini';
            iconData = Icons.schedule;
            break;
          case 1:
            message = 'Tidak ada event yang berlangsung';
            submessage = 'Event yang sedang berlangsung akan muncul di sini';
            iconData = Icons.play_circle_outline;
            break;
          case 2:
            message = 'Tidak ada event yang selesai';
            submessage = 'Event yang telah selesai akan muncul di sini';
            iconData = Icons.check_circle_outline;
            break;
        }
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 64,
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

    return RefreshIndicator(
      onRefresh: () async {
        _loadEvents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Placeholder for image
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.primary.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(event.category),
                            size: 48,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.category,
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: event.statusColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: event.statusColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          event.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Registration Status
                    if (event.isUpcoming)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: event.isRegistrationOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: (event.isRegistrationOpen ? Colors.green : Colors.red).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.isRegistrationOpen ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.isRegistrationOpen ? 'Buka' : 'Tutup',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
            // Event Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Price Row
                  Row(
                    children: [
                      // Category Chip - Dengan Flexible untuk responsive
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getCategoryColor(event.category).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(event.category),
                                size: 12,
                                color: _getCategoryColor(event.category),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  event.category,
                                  style: TextStyle(
                                    color: _getCategoryColor(event.category),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: event.isFree ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isFree ? 'GRATIS' : 'Rp ${NumberFormat('#,###').format(event.price)}',
                          style: TextStyle(
                            color: event.isFree ? Colors.green : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Short Description
                  Text(
                    event.shortDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Event Details
                  _buildEventInfo(Icons.event, DateFormat('dd MMM yyyy, HH:mm').format(event.startDate)),
                  const SizedBox(height: 6),
                  _buildEventInfo(Icons.location_on, event.location),
                  const SizedBox(height: 6),
                  _buildEventInfo(Icons.business, event.organizer),
                  const SizedBox(height: 12),
                  // Participants Info & Register Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${event.currentParticipants}/${event.maxParticipants}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Quick Register Button
                      if (event.isRegistrationOpen)
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(event.registrationUrl),
                          icon: const Icon(Icons.app_registration, size: 16),
                          label: const Text('Daftar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper methods untuk kategori
  IconData _getCategoryIcon(String category) {
    switch (category) {
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
}