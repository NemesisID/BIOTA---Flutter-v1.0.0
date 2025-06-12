class Data {
  final int? id;
  final String? image;
  final String speciesName;
  final String latinName;
  final String category;
  final String habitat;
  final String status;
  final String description;
  final String? funFact;
  final int userId;
  final int isApproved;
  final String createdAt;
  final double? latitude; // Tambahkan field latitude
  final double? longitude; // Tambahkan field longitude

  Data({
    this.id,
    this.image,
    required this.speciesName,
    required this.latinName,
    required this.category,
    required this.habitat,
    required this.status,
    required this.description,
    this.funFact,
    required this.userId,
    this.isApproved = 0,
    required this.createdAt,
    this.latitude, // Tambahkan di constructor
    this.longitude, // Tambahkan di constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'speciesName': speciesName,
      'latinName': latinName,
      'category': category,
      'habitat': habitat,
      'status': status,
      'description': description,
      'funFact': funFact,
      'userId': userId,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'latitude': latitude, // Tambahkan ke map
      'longitude': longitude, // Tambahkan ke map
    };
  }

  factory Data.fromMap(Map<String, dynamic> map) {
    return Data(
      id: map['id'],
      image: map['image'],
      speciesName: map['speciesName'] ?? '',
      latinName: map['latinName'] ?? '',
      category: map['category'] ?? '',
      habitat: map['habitat'] ?? '',
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      funFact: map['funFact'],
      userId: map['userId'] ?? 0,
      isApproved: map['isApproved'] ?? 0,
      createdAt: map['createdAt'] ?? '',
      latitude: map['latitude'] as double?, // Ambil dari map
      longitude: map['longitude'] as double?, // Ambil dari map
    );
  }
}