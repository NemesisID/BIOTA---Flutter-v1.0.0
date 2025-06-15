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
  final Data? focusSpecies;
  
  const ExploreScreen({super.key, this.focusSpecies});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final MapController _mapController = MapController();
  
  List<Data> _speciesList = [];
  bool _isLoading = true;
  Position? _currentPosition;
  LatLng _currentCenter = const LatLng(-7.2575, 112.7521); // Default Surabaya
  double _currentZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSpecies != null && 
        widget.focusSpecies != oldWidget.focusSpecies) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnSpecies(widget.focusSpecies!);
      });
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadSpeciesData();
    
    if (widget.focusSpecies != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnSpecies(widget.focusSpecies!);
      });
    }
  }

  void _focusOnSpecies(Data species) {
    if (species.latitude != null && species.longitude != null) {
      _mapController.move(
        LatLng(species.latitude!, species.longitude!),
        16.0,
      );
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showSpeciesDetail(species);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
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
        print('Current location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadSpeciesData() async {
    try {
      print('=== LOADING SPECIES DATA FROM DATABASE ===');
      
      // Load data dari database (termasuk dummy data yang sudah di-inject di homepage)
      final species = await _databaseHelper.getApprovedSpecies();
      print('Total species from database: ${species.length}');
      
      // Debug data yang ada di database
      for (var s in species) {
        print('DB Species: ${s.speciesName} - Approved: ${s.isApproved} - Lat: ${s.latitude}, Lng: ${s.longitude} - Image: ${s.image}');
      }
      
      // Filter species yang memiliki koordinat valid
      final speciesWithLocation = species.where((s) => 
        s.latitude != null && 
        s.longitude != null &&
        s.latitude != 0 &&
        s.longitude != 0
      ).toList();
      
      print('Species with valid coordinates: ${speciesWithLocation.length}');
      
      for (var s in speciesWithLocation) {
        print('Valid Species: ${s.speciesName} at (${s.latitude}, ${s.longitude}) - Image: ${s.image}');
      }
      
      setState(() {
        _speciesList = speciesWithLocation;
        _isLoading = false;
      });
      
      print('=== SPECIES DATA LOADED SUCCESSFULLY ===');
    } catch (e) {
      print('Error loading species data: $e');
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
    double newZoom = (_mapController.zoom + 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.center, newZoom);
  }

  void _zoomOut() {
    double newZoom = (_mapController.zoom - 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.center, newZoom);
  }

  // Enhanced species marker with image support
  Widget _buildSpeciesMarker(Data species) {
    return GestureDetector(
      onTap: () {
        print('Marker tapped: ${species.speciesName}');
        _showSpeciesDetail(species);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
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
          child: _buildMarkerImage(species),
        ),
      ),
    );
  }

  // Enhanced image builder for markers - FIXED VERSION
  Widget _buildMarkerImage(Data species) {
    print('=== MARKER IMAGE BUILDER ===');
    print('Species: ${species.speciesName}, Image Path: ${species.image}');

    if (species.image != null && species.image!.isNotEmpty) {
      final imagePath = species.image!;
      
      // Asset image (prioritas pertama untuk dummy data)
      if (imagePath.startsWith('assets/')) {
        print('Attempting to load ASSET for marker: $imagePath');
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: 44, // Explicit width
          height: 44, // Explicit height
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            print('!!!!!! ASSET LOADING ERROR FOR MARKER !!!!!!');
            print('Species: ${species.speciesName}');
            print('Path: $imagePath');
            print('Error Object Type: ${error.runtimeType}');
            print('Error: $error');
            // print('StackTrace: $stackTrace'); // Bisa sangat panjang, aktifkan jika perlu
            print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            return _buildDefaultMarkerIcon(species); // Fallback
          },
        );
      }
      // Network image (URL)
      else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        print('✓ Loading network image for marker: $imagePath');
        return Container(
          width: 44,
          height: 44,
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(species.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _getStatusColor(species.status),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Network error for marker: $imagePath - $error');
              return _buildDefaultMarkerIcon(species);
            },
          ),
        );
      }
      // Local file
      else if (File(imagePath).existsSync()) {
        print('✓ Loading file image for marker: $imagePath');
        return Container(
          width: 44,
          height: 44,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ File error for marker: $imagePath - $error');
              return _buildDefaultMarkerIcon(species);
            },
          ),
        );
      }
    }
    
    // Fallback to default icon
    print('Marker: No valid image path, using default icon for ${species.speciesName}');
    return _buildDefaultMarkerIcon(species);
  }

  Widget _buildDefaultMarkerIcon(Data species) {
    print('Building default marker icon for: ${species.speciesName}');
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getStatusColor(species.status).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        species.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
        color: _getStatusColor(species.status),
        size: 24,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'banyak':
        return Colors.green;
      case 'rentan':
        return Colors.orange;
      case 'terancam punah':
        return Colors.red;
      default: // Pastikan ada return statement di sini
        return Colors.grey; // Mengembalikan warna default jika status tidak dikenali
    }
  }

  // Enhanced species detail with better image handling
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
                  
                  // Enhanced species image
                  _buildDetailImage(species),
                  
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

  // Enhanced detail image builder - FIXED VERSION
  Widget _buildDetailImage(Data species) {
    print('=== DETAIL IMAGE BUILDER ===');
    print('Species: ${species.speciesName}, Image Path: ${species.image}');

    if (species.image != null && species.image!.isNotEmpty) {
      final imagePath = species.image!;
      
      // Asset image (prioritas pertama untuk dummy data)
      if (imagePath.startsWith('assets/')) {
        print('Attempting to load ASSET for detail: $imagePath');
        return Container( 
            width: double.infinity,
            height: 200,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        print('!!!!!! ASSET LOADING ERROR FOR DETAIL !!!!!!');
                        print('Species: ${species.speciesName}');
                        print('Path: $imagePath');
                        print('Error Object Type: ${error.runtimeType}');
                        print('Error: $error');
                        // print('StackTrace: $stackTrace'); // Bisa sangat panjang, aktifkan jika perlu
                        print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                        return _buildDefaultDetailImage(species); // Fallback
                    },
                ),
            ),
        );
      }
      // Network image (URL)
      else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        print('✓ Loading network image for detail: $imagePath');
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imagePath,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(species.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: _getStatusColor(species.status),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat gambar...',
                        style: TextStyle(
                          color: _getStatusColor(species.status),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Network error for detail: $imagePath - $error');
                return _buildDefaultDetailImage(species);
              },
            ),
          ),
        );
      }
      // Local file
      else if (File(imagePath).existsSync()) {
        print('✓ Loading file image for detail: $imagePath');
        return Container(
          height: 200,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ File error for detail: $imagePath - $error');
                return _buildDefaultDetailImage(species);
              },
            ),
          ),
        );
      }
    }
    
    // Fallback to default image
    print('Detail: No valid image path, using default image for ${species.speciesName}');
    return _buildDefaultDetailImage(species);
  }

  Widget _buildDefaultDetailImage(Data species) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _getStatusColor(species.status).withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            species.category.toLowerCase() == 'hewan' ? Icons.pets : Icons.eco,
            size: 80,
            color: _getStatusColor(species.status),
          ),
          const SizedBox(height: 12),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(
              color: _getStatusColor(species.status),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    print('Building map with ${_speciesList.length} species markers');
    
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
          print('Map tapped at: ${point.latitude}, ${point.longitude}');
        },
      ),
      children: [
        // Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.biota_2',
          maxZoom: 18,
          errorTileCallback: (tile, error, stackTrace) {
            print('Tile loading error: $error');
          },
        ),
        
        // Current Location Marker
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

        // Species Markers with enhanced image support
        if (_speciesList.isNotEmpty)
          MarkerLayer(
            markers: _speciesList.map((species) {
              print('Creating marker for ${species.speciesName} at (${species.latitude}, ${species.longitude}) with image: ${species.image}');
              return Marker(
                point: LatLng(species.latitude!, species.longitude!),
                width: 50,
                height: 50,
                child: _buildSpeciesMarker(species),
              );
            }).toList(),
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
          
          // Debug info
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Species: ${_speciesList.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          // Add species button
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
          
          // Bottom controls
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