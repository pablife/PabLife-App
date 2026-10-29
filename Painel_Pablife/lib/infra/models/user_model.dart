import 'dart:convert';

enum UserRole {
  user('user'),
  admin('admin'),
  professional('professional');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.user,
    );
  }
}

enum UserStatus {
  active('active'),
  deactivated('deactivated'),
  deleted('deleted');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Ativo';
      case UserStatus.deactivated:
        return 'Desativado';
      case UserStatus.deleted:
        return 'Excluído';
    }
  }
}

enum ProfessionalType {
  nutritionist('nutritionist'),
  psychologist('psychologist');

  final String value;
  const ProfessionalType(this.value);

  static ProfessionalType fromString(String value) {
    return ProfessionalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfessionalType.nutritionist,
    );
  }

  String get displayName {
    switch (this) {
      case ProfessionalType.nutritionist:
        return 'Nutricionista';
      case ProfessionalType.psychologist:
        return 'Psicólogo';
    }
  }
}

class UserModel {
  final String? id;
  final String fullName;
  final String email;
  final String phone;
  final String cpfDocument;
  final String? imageUrl;
  final bool termsAccepted;
  final UserRole role;
  final UserStatus status;
  final ProfessionalType? professionalType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.cpfDocument,
    this.imageUrl,
    required this.termsAccepted,
    required this.role,
    required this.status,
    this.professionalType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'cpf_document': cpfDocument,
      if (imageUrl != null) 'image_url': imageUrl,
      'terms_accepted': termsAccepted,
      'role': role.value,
      'status': status.value,
      if (professionalType != null)
        'professional_type': professionalType!.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      cpfDocument: map['cpf_document'] ?? '',
      imageUrl: map['image_url'],
      termsAccepted: map['terms_accepted'] ?? false,
      role: UserRole.fromString(map['role'] ?? 'user'),
      status: UserStatus.fromString(map['status'] ?? 'active'),
      professionalType: map['professional_type'] != null
          ? ProfessionalType.fromString(map['professional_type'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? cpfDocument,
    String? imageUrl,
    bool? termsAccepted,
    UserRole? role,
    UserStatus? status,
    ProfessionalType? professionalType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cpfDocument: cpfDocument ?? this.cpfDocument,
      imageUrl: imageUrl ?? this.imageUrl,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      role: role ?? this.role,
      status: status ?? this.status,
      professionalType: professionalType ?? this.professionalType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
