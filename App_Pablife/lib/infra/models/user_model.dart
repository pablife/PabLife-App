import 'dart:convert';
import 'user_role.dart';
import 'user_status.dart';
import 'professional_type.dart';

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
  final String? oneSignalUserId;

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
    this.oneSignalUserId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'cpf_document': cpfDocument,
      'image_url': imageUrl,
      'terms_accepted': termsAccepted,
      'role': role.value,
      'status': status.value,
      'professional_type': professionalType?.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'one_signal_user_id': oneSignalUserId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
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
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      oneSignalUserId: map['one_signal_user_id'],
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
    String? oneSignalUserId,
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
      oneSignalUserId: oneSignalUserId ?? this.oneSignalUserId,
    );
  }
}
