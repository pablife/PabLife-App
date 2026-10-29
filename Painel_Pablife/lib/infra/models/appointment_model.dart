import 'dart:convert';

class AppointmentModel {
  final String id;
  final String scheduledBy; // user que agendou
  final String professionalId;
  final String appointmentTimeId;
  final DateTime startOfScheduledWindow;
  final DateTime endOfScheduledWindow;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Campos extras para exibição
  final String? professionalName;
  final String? professionalType;
  final String? userName;
  final String? userEmail;

  AppointmentModel({
    required this.id,
    required this.scheduledBy,
    required this.professionalId,
    required this.appointmentTimeId,
    required this.startOfScheduledWindow,
    required this.endOfScheduledWindow,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.professionalName,
    this.professionalType,
    this.userName,
    this.userEmail,
  });

  // Status calculado baseado nos timestamps
  String get displayStatus {
    if (deletedAt != null) return 'Cancelado';
    if (finishedAt != null) return 'Concluído';
    if (startedAt != null) return 'Em andamento';
    if (DateTime.now().isAfter(endOfScheduledWindow)) return 'Atrasado';
    return 'Agendado';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'scheduled_by': scheduledBy,
      'professional_id': professionalId,
      'appointment_time_id': appointmentTimeId,
      'start_of_scheduled_window': startOfScheduledWindow.toIso8601String(),
      'end_of_scheduled_window': endOfScheduledWindow.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      scheduledBy: map['scheduled_by'] ?? '',
      professionalId: map['professional_id'] ?? '',
      appointmentTimeId: map['appointment_time_id'] ?? '',
      startOfScheduledWindow: DateTime.parse(map['start_of_scheduled_window']),
      endOfScheduledWindow: DateTime.parse(map['end_of_scheduled_window']),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'])
          : null,
      finishedAt: map['finished_at'] != null
          ? DateTime.parse(map['finished_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      professionalName: map['professional_name'],
      professionalType: map['professional_type'],
      userName: map['user_name'],
      userEmail: map['user_email'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AppointmentModel.fromJson(String source) =>
      AppointmentModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
