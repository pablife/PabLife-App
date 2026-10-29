import 'dart:convert';

class MentoriaModuleModel {
  final String id;
  final String mentoringId;
  final String title;
  final String colorHex;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MentoriaModuleModel({
    required this.id,
    required this.mentoringId,
    required this.title,
    String? colorHex,
    required this.createdAt,
    this.updatedAt,
  }) : colorHex = (colorHex == null || colorHex.isEmpty)
           ? defaultMentoriaModuleColor
           : colorHex;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'mentoring_id': mentoringId,
      'title': title,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MentoriaModuleModel.fromMap(Map<String, dynamic> map) {
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

    return MentoriaModuleModel(
      id: map['id']?.toString() ?? '',
      mentoringId:
          map['mentoring_id']?.toString() ??
          map['mentoringId']?.toString() ??
          '',
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      colorHex: map['color_hex']?.toString() ?? map['color']?.toString(),
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: parseNullableDate(map['updated_at'] ?? map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MentoriaModuleModel.fromJson(String source) =>
      MentoriaModuleModel.fromMap(json.decode(source) as Map<String, dynamic>);

  MentoriaModuleModel copyWith({
    String? id,
    String? mentoringId,
    String? title,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentoriaModuleModel(
      id: id ?? this.id,
      mentoringId: mentoringId ?? this.mentoringId,
      title: title ?? this.title,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const String defaultMentoriaModuleColor = '0xFF00343C';
