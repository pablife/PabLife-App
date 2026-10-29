import 'dart:convert';

enum PatientRecordType {
  mealPlan('meal_plan'),
  prescription('prescription'),
  observation('observation'),
  note('note'),
  reflection('reflection'),
  practice('practice');

  final String value;
  const PatientRecordType(this.value);

  static PatientRecordType fromString(String value) {
    return PatientRecordType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PatientRecordType.observation,
    );
  }

  String get displayName {
    switch (this) {
      case PatientRecordType.mealPlan:
        return 'Plano Alimentar';
      case PatientRecordType.prescription:
        return 'Receita';
      case PatientRecordType.observation:
        return 'Observação';
      case PatientRecordType.note:
        return 'Anotação';
      case PatientRecordType.reflection:
        return 'Reflexão';
      case PatientRecordType.practice:
        return 'Prática';
    }
  }
}

class PatientRecordModel {
  final String id;
  final String patientId;
  final PatientRecordType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  PatientRecordModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patient_id': patientId,
      'type': type.value,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory PatientRecordModel.fromMap(Map<String, dynamic> map) {
    return PatientRecordModel(
      id: map['id'] ?? '',
      patientId: map['patient_id'] ?? '',
      type: PatientRecordType.fromString(map['type'] ?? 'observation'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PatientRecordModel.fromJson(String source) =>
      PatientRecordModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
