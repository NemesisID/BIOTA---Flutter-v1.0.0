import 'package:shared_preferences/shared_preferences.dart';
import 'package:biota_2/services/database_helper.dart';
import 'package:biota_2/models/user.dart'; // Tambahkan import ini

class AuthService {
  static final AuthService instance = AuthService._init();
  static const String KEY_IS_LOGGED_IN = 'is_logged_in';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_IS_ADMIN = 'is_admin';
  static const String KEY_USER_NAME = 'user_name';
  
  AuthService._init();

  // Tambahkan method getCurrentUser yang hilang
  static Future<User?> getCurrentUser() async {
    try {
      final userId = await instance.getUserId();
      if (userId != null) {
        final db = await DatabaseHelper.instance.database;
        final result = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (result.isNotEmpty) {
          return User.fromMap(result.first);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Method instance untuk getCurrentUser
  Future<User?> getCurrentUserInstance() async {
    return getCurrentUser();
  }

  Future<bool> login(String loginId, String password) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'users',
        where: '(email = ? OR username = ?) AND password = ?',
        whereArgs: [loginId, loginId, password],
      );

      if (result.isNotEmpty) {
        final userId = result.first['id'] as int;
        final isAdmin = result.first['isAdmin'] as int;
        final userName = result.first['fullName'] as String?;
        await saveLoginStatus(userId, isAdmin: isAdmin, userName: userName);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Gagal melakukan login: $e');
    }
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getInt(KEY_IS_ADMIN) ?? 0;
    return isAdmin == 1;
  }

  Future<void> saveLoginStatus(int userId, {int? isAdmin, String? userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_IS_LOGGED_IN, true);
    await prefs.setInt(KEY_USER_ID, userId);
    if (isAdmin != null) await prefs.setInt(KEY_IS_ADMIN, isAdmin);
    if (userName != null) await prefs.setString(KEY_USER_NAME, userName);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
  }
  
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(KEY_USER_ID);
  }

  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(KEY_IS_ADMIN);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_NAME);
  }

  Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_IS_LOGGED_IN);
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_IS_ADMIN);
    await prefs.remove(KEY_USER_NAME);
  }

  Future<void> logout() async {
    try {
      await clearLoginStatus();
    } catch (e) {
      throw Exception('Gagal melakukan logout: $e');
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
  
      // Cek apakah username atau email sudah digunakan
      final existingUser = await db.query(
        'users',
        where: 'username = ? OR email = ?',
        whereArgs: [username, email],
      );
  
      if (existingUser.isNotEmpty) {
        return false; // Username atau email sudah digunakan
      }
  
      // Insert user baru
      await db.insert('users', {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'isAdmin': 0, // Default isAdmin = 0 untuk user baru
      });
  
      return true;
    } catch (e) {
      throw Exception('Gagal melakukan registrasi: $e');
    }
  }

  Future<int?> getCurrentUserId() async {
    return getUserId();
  }
}