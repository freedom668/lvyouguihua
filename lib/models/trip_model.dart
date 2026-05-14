/// 旅游行程数据模型 —— 支持 JSON（MCP）和 Map（SQLite）双序列化。
class TripModel {
  final int id;
  final String title;
  final String city;
  final String imageUrl;
  final String description;
  final int days;
  final double price;
  final bool isFavorite;
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.title,
    required this.city,
    required this.imageUrl,
    required this.description,
    required this.days,
    required this.price,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ========== JSON 序列化（用于 MCP / 网络通信） ==========

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as int,
      title: json['title'] as String,
      city: json['city'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      days: json['days'] as int,
      price: (json['price'] as num).toDouble(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'imageUrl': imageUrl,
      'description': description,
      'days': days,
      'price': price,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ========== SQLite 序列化 ==========

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as int,
      title: map['title'] as String,
      city: map['city'] as String,
      imageUrl: map['image_url'] as String,
      description: map['description'] as String,
      days: map['days'] as int,
      price: (map['price'] as num).toDouble(),
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'image_url': imageUrl,
      'description': description,
      'days': days,
      'price': price,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TripModel copyWith({
    int? id,
    String? title,
    String? city,
    String? imageUrl,
    String? description,
    int? days,
    double? price,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      days: days ?? this.days,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
