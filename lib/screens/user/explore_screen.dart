import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biota_2/constants/colors.dart';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/screens/user/add_species_form.dart';
import 'dart:io';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final MapController _mapController = MapController();
  
  List<Data> _speciesList = [];
  bool _isLoading = true;
  Position? _currentPosition;
  LatLng _currentCenter = const LatLng(-6.2088, 106.8456); // Default Jakarta
  double _currentZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadSpeciesData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadSpeciesData() async {
    try {
      final species = await _databaseHelper.getApprovedSpecies();
      setState(() {
        _speciesList = species.where((s) => s.latitude != null && s.longitude != null).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading species data: $e')),
        );
      }
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi saat ini tidak tersedia')),
      );
    }
  }

  void _zoomIn() {
    _mapController.move(_mapController.center, _mapController.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.center, _mapController.zoom - 1);
  }

  Widget _buildSpeciesMarker(Data species) {
    return GestureDetector(
      onTap: () => _showSpeciesDetail(species),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getStatusColor(species.status),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: species.image != null && File(species.image!).existsSync()
              ? Image.file(
                  File(species.image!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultMarkerIcon(species);
                  },
                )
              : _buildDefaultMarkerIcon(species),
        ),
      ),
    );
  }

  Widget _buildDefaultMarkerIcon(Data species) {
    return Container(
      color: _getStatusColor(species.status).withOpacity(0.1),
      child: Icon(
        species.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
        color: _getStatusColor(species.status),
        size: 30,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aman':
      case 'tidak rentan':
        return Colors.green;
      case 'rentan':
        return Colors.orange;
      case 'terancam punah':
        return Colors.red;
      case 'kritis':
        return Colors.red.shade700;
      case 'punah di alam liar':
        return Colors.purple;
      case 'punah':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _showSpeciesDetail(Data species) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
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
                  
                  // Species image
                  if (species.image != null && File(species.image!).existsSync())
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(species.image!)),
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
                        color: _getStatusColor(species.status).withOpacity(0.1),
                      ),
                      child: Icon(
                        species.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                        size: 80,
                        color: _getStatusColor(species.status),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Species name and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              species.speciesName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              species.latinName,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(species.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(species.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          species.status,
                          style: TextStyle(
                            color: _getStatusColor(species.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category and habitat
                  Row(
                    children: [
                      Icon(
                        species.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        species.category,
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
                          species.habitat,
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
                    species.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  
                  if (species.funFact != null && species.funFact!.isNotEmpty) ...[
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
                              species.funFact!,
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
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: _currentZoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        onMapReady: () {
          print('Map is ready');
        },
        onTap: (tapPosition, point) {
          _showLocationDialog(point);
        },
      ),
      children: [
        // Tile Layer dengan fallback
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.biota_2',
          maxZoom: 18,
          errorTileCallback: (tile, error, stackTrace) {
            print('Tile loading error: $error');
          },
          fallbackUrl: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        
        // Current Location Marker - Updated to simple blue circle
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 20,
                height: 20,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // Species Markers
        MarkerLayer(
          markers: _speciesList
              .where((species) => species.latitude != null && species.longitude != null)
              .map((species) => _buildSpeciesMarker(species))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMapView(),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          
          // Top left: Logo and title
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'BIOTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top right: Add species button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddSpeciesForm(),
                      ),
                    );
                    if (result == true) {
                      _loadSpeciesData();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ajukan Data',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom left: Current location button
          Positioned(
            bottom: 20,
            left: 16,
            child: FloatingActionButton(
              heroTag: "currentLocation",
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),
          
          // Bottom right: Zoom controls
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.zoom_in,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.zoom_out,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}