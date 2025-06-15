class FunFact {
  final int? id;
  final String title;
  final String description;
  final String icon;
  final String backgroundColor;
  final String updatedAt;

  FunFact({
    this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'backgroundColor': backgroundColor,
      'updatedAt': updatedAt,
    };
  }

  factory FunFact.fromMap(Map<String, dynamic> map) {
    return FunFact(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      backgroundColor: map['backgroundColor'] ?? '',
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  FunFact copyWith({
    int? id,
    String? title,
    String? description,
    String? icon,
    String? backgroundColor,
    String? updatedAt,
  }) {
    return FunFact(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}