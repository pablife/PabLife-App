import 'dart:convert';

class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String redirectUrl;
  final bool isActive;
  final DateTime? expirationAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.redirectUrl,
    required this.isActive,
    this.expirationAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isExpired {
    if (expirationAt == null) return false;
    return DateTime.now().isAfter(expirationAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'redirect_url': redirectUrl,
      'is_active': isActive,
      'expiration_at': expirationAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['image_url'] ?? '',
      redirectUrl: map['redirect_url'] ?? '',
      isActive: map['is_active'] ?? false,
      expirationAt: map['expiration_at'] != null
          ? DateTime.parse(map['expiration_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BannerModel.fromJson(String source) =>
      BannerModel.fromMap(json.decode(source) as Map<String, dynamic>);

  BannerModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? redirectUrl,
    bool? isActive,
    DateTime? expirationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      isActive: isActive ?? this.isActive,
      expirationAt: expirationAt ?? this.expirationAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
