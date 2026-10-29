import 'dart:convert';

class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    this.metadata,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isRead => readAt != null;

  String? get type => metadata?['type'] as String?;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'metadata': metadata,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      message: map['message'] as String,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(json.decode(source) as Map<String, dynamic>);

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
