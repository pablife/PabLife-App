import 'dart:convert';

enum ValidationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const ValidationStatus(this.value);

  static ValidationStatus fromString(String value) {
    return ValidationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ValidationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ValidationStatus.pending:
        return 'Pendente';
      case ValidationStatus.approved:
        return 'Aprovado';
      case ValidationStatus.rejected:
        return 'Rejeitado';
    }
  }
}

class ProfessionalModel {
  final String id;
  final String userId;
  final String type; // nutritionist, psychologist
  final String? validationDocumentUrl;
  final ValidationStatus validationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final String? name;

  ProfessionalModel({
    required this.id,
    required this.userId,
    required this.type,
    this.validationDocumentUrl,
    required this.validationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type,
      if (validationDocumentUrl != null)
        'validation_document_url': validationDocumentUrl,
      'validation_status': validationStatus.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory ProfessionalModel.fromMap(Map<String, dynamic> map) {
    return ProfessionalModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      validationDocumentUrl: map['validation_document_url'],
      validationStatus: ValidationStatus.fromString(
        map['validation_status'] ?? 'pending',
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      name: map['user']?['full_name'],
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
    ValidationStatus? validationStatus,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, String> typesInPt = {
    'nutritionist': 'Nutricionista',
    'psychologist': 'Psicólogo(a)',
  };
  String? get translatedType => typesInPt[type];
}

// Model combinado para exibição
class ProfessionalWithUserModel {
  final ProfessionalModel professional;
  final dynamic user; // Vai conter UserModel quando precisar

  ProfessionalWithUserModel({required this.professional, required this.user});
}
