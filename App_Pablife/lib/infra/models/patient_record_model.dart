import 'package:intl/intl.dart';

enum PatientRecordType {
  mealPlan('meal_plan'),
  prescription('prescription'),
  observation('observation'),
  note('note'),
  reflection('reflection'),
  practice('practice');

  final String value;
  const PatientRecordType(this.value);

  /// Plano alimentar, prescrição e prática nascem compartilhados com o
  /// paciente; o resto nasce privado (só o profissional que escreveu vê).
  bool get sharedByDefault =>
      this == mealPlan || this == prescription || this == practice;

  static PatientRecordType fromString(String value) {
    return PatientRecordType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PatientRecordType.observation,
    );
  }
}

class PatientRecordModel {
  final String id;
  final String patientId;
  final PatientRecordType type;
  final String title;
  final String description;

  /// Compartilhada: o paciente vê. Privada: só o profissional que escreveu.
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PatientRecordModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.title,
    required this.description,
    this.isShared = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(createdAt);

  factory PatientRecordModel.fromMap(Map<String, dynamic> map) {
    return PatientRecordModel(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      type: PatientRecordType.fromString(map['type']?.toString() ?? ''),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isShared: map['visibility'] == null
          ? PatientRecordType.fromString(
              map['type']?.toString() ?? '',
            ).sharedByDefault
          : map['visibility'] == 'shared',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? ''),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'type': type.value,
      'title': title,
      'description': description,
      'visibility': isShared ? 'shared' : 'private',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  PatientRecordModel copyWith({
    String? id,
    String? patientId,
    PatientRecordType? type,
    String? title,
    String? description,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PatientRecordModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
