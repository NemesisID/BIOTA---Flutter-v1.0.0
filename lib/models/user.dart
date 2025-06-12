class User {
  final int id;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final bool isAdmin;
  final String? profileImagePath;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    this.profileImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
      'isAdmin': isAdmin ? 1 : 0,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? 0,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      isAdmin: (map['isAdmin'] ?? 0) == 1,
      profileImagePath: map['profileImagePath'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Method untuk membuat copy user dengan perubahan
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? email,
    String? fullName,
    bool? isAdmin,
    String? profileImagePath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isAdmin: isAdmin ?? this.isAdmin,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}