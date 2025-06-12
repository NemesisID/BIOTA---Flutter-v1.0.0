import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:biota_2/models/user.dart';
import 'package:biota_2/models/data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biota.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Naikkan versi database
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0,
        profileImagePath TEXT,
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabel data dengan semua kolom yang diperlukan
    await db.execute('''
      CREATE TABLE data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image TEXT,
        speciesName TEXT NOT NULL,
        latinName TEXT NOT NULL,
        category TEXT NOT NULL,
        habitat TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT NOT NULL,
        funFact TEXT,
        userId INTEGER NOT NULL,
        isApproved INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insert admin default
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'email': 'admin@biota.com',
      'fullName': 'Administrator',
      'isAdmin': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Tambah kolom profileImagePath jika belum ada
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profileImagePath TEXT');
      } catch (e) {
        print('Column profileImagePath might already exist: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Migrasi dari data_species ke data jika diperlukan
      try {
        // Cek apakah tabel data_species ada
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='data_species'");
        if (tables.isNotEmpty) {
          // Buat tabel data baru dengan struktur lengkap
          await db.execute('''
            CREATE TABLE IF NOT EXISTS data_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image TEXT,
              speciesName TEXT NOT NULL,
              latinName TEXT NOT NULL,
              category TEXT NOT NULL,
              habitat TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT NOT NULL,
              funFact TEXT,
              userId INTEGER NOT NULL,
              isApproved INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              FOREIGN KEY (userId) REFERENCES users (id)
            )
          ''');
          
          // Migrasi data dari data_species ke data_new
          final oldData = await db.rawQuery('SELECT * FROM data_species');
          for (var row in oldData) {
            await db.insert('data_new', {
              'speciesName': row['speciesName'] ?? '',
              'latinName': row['scientificName'] ?? row['latinName'] ?? '',
              'category': row['category'] ?? 'Hewan',
              'habitat': row['habitat'] ?? '',
              'status': row['status'] ?? 'Aman',
              'description': row['description'] ?? '',
              'funFact': null,
              'userId': row['userId'] ?? 1,
              'isApproved': row['isApproved'] ?? 0,
              'createdAt': row['dateSubmitted'] ?? row['createdAt'] ?? DateTime.now().toIso8601String(),
              'image': row['imagePath'] ?? row['image'],
              'latitude': row['latitude'],
              'longitude': row['longitude'],
            });
          }
          
          // Hapus tabel lama dan rename tabel baru
          await db.execute('DROP TABLE data_species');
          await db.execute('ALTER TABLE data_new RENAME TO data');
        }
      } catch (e) {
        print('Migration error: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Pastikan tabel data memiliki semua kolom yang diperlukan
      try {
        // Cek apakah tabel data ada
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='data'");
        if (tables.isEmpty) {
          // Jika tabel data tidak ada, buat ulang
          await db.execute('''
            CREATE TABLE data(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image TEXT,
              speciesName TEXT NOT NULL,
              latinName TEXT NOT NULL,
              category TEXT NOT NULL,
              habitat TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT NOT NULL,
              funFact TEXT,
              userId INTEGER NOT NULL,
              isApproved INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              FOREIGN KEY (userId) REFERENCES users (id)
            )
          ''');
        } else {
          // Jika tabel data ada, cek dan tambahkan kolom yang hilang
          final columns = await db.rawQuery('PRAGMA table_info(data)');
          final columnNames = columns.map((col) => col['name'] as String).toList();
          
          if (!columnNames.contains('image')) {
            await db.execute('ALTER TABLE data ADD COLUMN image TEXT');
          }
          if (!columnNames.contains('latitude')) {
            await db.execute('ALTER TABLE data ADD COLUMN latitude REAL');
          }
          if (!columnNames.contains('longitude')) {
            await db.execute('ALTER TABLE data ADD COLUMN longitude REAL');
          }
          if (!columnNames.contains('funFact')) {
            await db.execute('ALTER TABLE data ADD COLUMN funFact TEXT');
          }
        }
      } catch (e) {
        print('Error ensuring data table structure: $e');
        // Jika ada error, drop dan buat ulang tabel
        try {
          await db.execute('DROP TABLE IF EXISTS data');
          await db.execute('''
            CREATE TABLE data(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image TEXT,
              speciesName TEXT NOT NULL,
              latinName TEXT NOT NULL,
              category TEXT NOT NULL,
              habitat TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT NOT NULL,
              funFact TEXT,
              userId INTEGER NOT NULL,
              isApproved INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              FOREIGN KEY (userId) REFERENCES users (id)
            )
          ''');
        } catch (recreateError) {
          print('Error recreating data table: $recreateError');
        }
      }
    }
  }

  // ========== USER METHODS ==========
  
  Future<User?> loginUser(String loginId, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: '(email = ? OR username = ?) AND password = ?',
        whereArgs: [loginId, loginId, password],
      );

      if (result.isNotEmpty) {
        return User.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateUserProfile(User user) async {
    try {
      final db = await database;
      return await db.update(
        'users',
        {
          'username': user.username,
          'email': user.email,
          'fullName': user.fullName,
          'profileImagePath': user.profileImagePath,
          // Jangan update password dan isAdmin di profile update
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    try {
      final db = await database;
      return await db.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Error updating user password: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameEmailAvailable(String username, String email, int currentUserId) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: '(username = ? OR email = ?) AND id != ?',
        whereArgs: [username, email, currentUserId],
      );
      return result.isEmpty; // true jika username/email belum digunakan
    } catch (e) {
      print('Error checking username/email availability: $e');
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'isAdmin = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    
    // Hapus semua data spesies yang dimiliki user ini terlebih dahulu
    await db.delete(
      'data',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    
    // Kemudian hapus user
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ========== DATA/SPECIES METHODS ==========

  Future<int> insertData(Data data) async {
    try {
      final db = await database;
      final result = await db.insert('data', data.toMap());
      print('Data inserted successfully with ID: $result');
      return result;
    } catch (e) {
      print('Error inserting data: $e');
      rethrow;
    }
  }

  Future<List<Data>> getAllData() async {
    final db = await database;
    final result = await db.query('data', orderBy: 'createdAt DESC');
    return result.map((map) => Data.fromMap(map)).toList();
  }

  Future<List<Data>> getAllSpecies() async {
    // Alias untuk getAllData untuk kompatibilitas
    return getAllData();
  }

  Future<List<Data>> getApprovedSpecies() async {
    final db = await database;
    final result = await db.query(
      'data',
      where: 'isApproved = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Data.fromMap(map)).toList();
  }

  Future<List<Data>> getPendingSpecies() async {
    final db = await database;
    final result = await db.query(
      'data',
      where: 'isApproved = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Data.fromMap(map)).toList();
  }

  Future<List<Data>> getRejectedSpecies() async {
    final db = await database;
    final result = await db.query(
      'data',
      where: 'isApproved = ?',
      whereArgs: [3],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Data.fromMap(map)).toList();
  }

  Future<List<Data>> searchSpecies(String query) async {
    final db = await database;
    final result = await db.query(
      'data',
      where: '(speciesName LIKE ? OR latinName LIKE ?) AND isApproved = ?',
      whereArgs: ['%$query%', '%$query%', 1],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Data.fromMap(map)).toList();
  }

  Future<Data?> getDataById(int id) async {
    final db = await database;
    final result = await db.query(
      'data',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Data.fromMap(result.first);
    }
    return null;
  }

  // ========== UPDATE & DELETE METHODS ==========

  Future<int> updateSpeciesApprovalStatus(int id, int status) async {
    final db = await database;
    return await db.update(
      'data',
      {'isApproved': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Alias untuk kompatibilitas dengan kode yang sudah ada
  Future<void> updateSpeciesApproval(int id, int isApproved) async {
    await updateSpeciesApprovalStatus(id, isApproved);
  }

  Future<void> updateDataApproval(int id, int status) async {
    await updateSpeciesApprovalStatus(id, status);
  }

  Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete(
      'data',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== STATISTICS METHODS ==========

  Future<Map<String, int>> getSpeciesStats() async {
    final db = await database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM data');
    final approvedResult = await db.rawQuery('SELECT COUNT(*) as count FROM data WHERE isApproved = 1');
    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM data WHERE isApproved = 0');
    final rejectedResult = await db.rawQuery('SELECT COUNT(*) as count FROM data WHERE isApproved = 3');

    return {
      'total': totalResult.first['count'] as int,
      'approved': approvedResult.first['count'] as int,
      'pending': pendingResult.first['count'] as int,
      'rejected': rejectedResult.first['count'] as int,
    };
  }

  Future<Map<String, int>> getUserStats() async {
    final db = await database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE isAdmin = 0');
    
    return {
      'total': totalResult.first['count'] as int,
    };
  }

  // ========== UTILITY METHODS ==========

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }

  // Method untuk debug - cek struktur tabel
  Future<void> printTableStructure() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA table_info(data)');
      print('Data table structure:');
      for (var column in result) {
        print('${column['name']}: ${column['type']}');
      }
    } catch (e) {
      print('Error checking table structure: $e');
    }
  }
}