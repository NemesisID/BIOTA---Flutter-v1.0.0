import 'dart:async';
import 'package:biota_2/models/data.dart';
import 'package:biota_2/services/database_helper.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // Stream controllers untuk real-time updates
  final StreamController<List<Data>> _speciesStreamController = 
      StreamController<List<Data>>.broadcast();
  final StreamController<void> _dataChangeStreamController = 
      StreamController<void>.broadcast();

  // Streams yang bisa didengarkan oleh widget lain
  Stream<List<Data>> get speciesStream => _speciesStreamController.stream;
  Stream<void> get dataChangeStream => _dataChangeStreamController.stream;

  List<Data> _cachedSpecies = [];
  DateTime? _lastUpdate;

  // Getter untuk cached data
  List<Data> get cachedSpecies => _cachedSpecies;

  // Load species data dan broadcast ke semua listeners
  Future<List<Data>> loadSpecies({bool forceRefresh = false}) async {
    try {
      // Check cache validity (refresh setiap 30 detik atau jika dipaksa)
      final now = DateTime.now();
      if (!forceRefresh && 
          _lastUpdate != null && 
          now.difference(_lastUpdate!).inSeconds < 30 &&
          _cachedSpecies.isNotEmpty) {
        print('DataService: Using cached species data');
        return _cachedSpecies;
      }

      print('DataService: Loading fresh species data from database...');
      
      // Load dari database
      final species = await _databaseHelper.getApprovedSpecies();
      
      // Filter species yang memiliki koordinat valid
      final speciesWithLocation = species.where((s) => 
        s.latitude != null && 
        s.longitude != null &&
        s.latitude != 0 &&
        s.longitude != 0
      ).toList();

      print('DataService: Loaded ${speciesWithLocation.length} species with valid coordinates');

      // Update cache
      _cachedSpecies = speciesWithLocation;
      _lastUpdate = now;
      
      // Broadcast ke semua listeners
      _speciesStreamController.add(_cachedSpecies);
      
      return _cachedSpecies;
    } catch (e) {
      print('DataService: Error loading species: $e');
      rethrow;
    }
  }

  // Method untuk notify bahwa data berubah
  void notifyDataChanged() {
    print('DataService: Notifying data change...');
    _dataChangeStreamController.add(null);
    // Force refresh data
    loadSpecies(forceRefresh: true);
  }

  // Method untuk clear cache
  void clearCache() {
    _cachedSpecies.clear();
    _lastUpdate = null;
  }

  // Method untuk refresh data secara manual
  Future<void> refreshData() async {
    await loadSpecies(forceRefresh: true);
  }

  // Dispose streams (panggil saat app ditutup)
  void dispose() {
    _speciesStreamController.close();
    _dataChangeStreamController.close();
  }
}