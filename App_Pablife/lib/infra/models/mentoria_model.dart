import 'dart:convert';

class MentoriaModel {
  final String id;
  final String title;
  final String description;
  final String author;
  final int durationMinutes;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isSaved;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MentoriaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.durationMinutes,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.isSaved = false,
    this.isLocked = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get durationLabel {
    if (durationMinutes <= 0) {
      return 'Não informado';
    }

    if (durationMinutes < 60) {
      return '${durationMinutes}h';
    }

    final duration = Duration(minutes: durationMinutes);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}min';
    }

    return '${duration.inMinutes}min';
  }

  String get bannerUrl =>
      imageUrl?.isNotEmpty == true ? imageUrl! : _fallbackImage;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'duration': durationMinutes,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'is_saved': isSaved,
      'is_locked': isLocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MentoriaModel.fromMap(Map<String, dynamic> map) {
    final category = map['category'] as Map<String, dynamic>?;

    int parseDuration(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return MentoriaModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      author: map['author']?.toString() ?? map['mentor']?.toString() ?? '',
      durationMinutes: parseDuration(
        map['duration'] ?? map['duration_minutes'] ?? map['durationMinutes'],
      ),
      categoryId:
          map['category_id']?.toString() ??
          map['categoryId']?.toString() ??
          category?['id']?.toString() ??
          '',
      categoryName:
          map['category_name']?.toString() ??
          map['category']?.toString() ??
          category?['name']?.toString() ??
          '',
      imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString(),
      isSaved: map['is_saved'] ?? map['isSaved'] ?? false,
      isLocked: map['is_locked'] ?? map['isLocked'] ?? false,
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: parseNullableDate(map['updated_at'] ?? map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MentoriaModel.fromJson(String source) =>
      MentoriaModel.fromMap(json.decode(source) as Map<String, dynamic>);

  MentoriaModel copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    int? durationMinutes,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isSaved,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentoriaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isSaved: isSaved ?? this.isSaved,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const String _fallbackImage =
    'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80';
