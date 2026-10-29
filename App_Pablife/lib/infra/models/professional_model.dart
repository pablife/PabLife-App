import 'dart:convert';

class ProfessionalModel {
  final String? id;
  final String userId;
  final String type;
  final String validationDocumentUrl;
  final String validationStatus;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ProfessionalModel({
    this.id,
    required this.userId,
    required this.type,
    required this.validationDocumentUrl,
    required this.validationStatus,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'validation_document_url': validationDocumentUrl,
      'validation_status': validationStatus,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory ProfessionalModel.fromMap(Map<String, dynamic> map) {
    return ProfessionalModel(
      id: map['id'],
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      validationDocumentUrl: map['validation_document_url'] ?? '',
      validationStatus: map['validation_status'] ?? 'pending',
      description: map['description'],
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

  factory ProfessionalModel.fromJson(String source) =>
      ProfessionalModel.fromMap(json.decode(source) as Map<String, dynamic>);

  ProfessionalModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? validationDocumentUrl,
    String? validationStatus,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProfessionalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      validationDocumentUrl:
          validationDocumentUrl ?? this.validationDocumentUrl,
      validationStatus: validationStatus ?? this.validationStatus,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
