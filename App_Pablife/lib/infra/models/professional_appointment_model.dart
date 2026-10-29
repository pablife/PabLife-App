import 'dart:convert';

import 'package:intl/intl.dart';

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  String toDbString() {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }
}

class ProfessionalAppointmentModel {
  final String id;
  final String scheduledBy;
  final String professionalId;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;
  final String? patientPhone;
  final String? professionalType;
  final String appointmentTimeId;
  final DateTime startOfScheduledWindow;
  final DateTime endOfScheduledWindow;
  final DateTime startAt;
  final DateTime? finishAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final AppointmentStatus status;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic>? professionalData;

  ProfessionalAppointmentModel({
    required this.id,
    required this.scheduledBy,
    required this.professionalId,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
    this.patientPhone,
    this.professionalType,
    required this.appointmentTimeId,
    required this.startOfScheduledWindow,
    required this.endOfScheduledWindow,
    required this.startAt,
    this.finishAt,
    this.startedAt,
    this.finishedAt,
    required this.status,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.professionalData,
  });

  bool get isCompleted => status == AppointmentStatus.completed;

  bool get isOngoing {
    if (isCompleted) return false;
    final now = DateTime.now();
    final effectiveFinish = finishAt ?? startAt.add(const Duration(hours: 1));
    return startAt.isBefore(now) && effectiveFinish.isAfter(now);
  }

  bool get isPast => isCompleted || startAt.isBefore(DateTime.now());

  bool get isLate {
    if (startedAt != null) return false;
    if (status != AppointmentStatus.scheduled) return false;
    final now = DateTime.now();
    final tenMinutesAfterStart = startAt.add(const Duration(minutes: 10));
    return now.isAfter(tenMinutesAfterStart);
  }

  bool get canStart {
    return status == AppointmentStatus.scheduled && startedAt == null;
  }

  bool get canMarkNoShow {
    return status == AppointmentStatus.scheduled && isLate;
  }

  String get formattedTime {
    if (isOngoing) {
      return 'Agora';
    }

    final now = DateTime.now();
    final appointmentDate = startAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );

    final hour = DateFormat('HH').format(appointmentDate);
    final minute = DateFormat('mm').format(appointmentDate);

    if (appointmentDay == today) {
      return 'Hoje às ${hour}h ${minute != '00' ? minute : ''}m';
    }

    final dateFormatted = DateFormat('dd/MM/yyyy').format(appointmentDate);
    return '$dateFormatted às ${hour}h';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'scheduled_by': scheduledBy,
      'professional_id': professionalId,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_image_url': patientImageUrl,
      'patient_phone': patientPhone,
      'professional_type': professionalType,
      'appointment_time_id': appointmentTimeId,
      'start_of_scheduled_window': startOfScheduledWindow.toIso8601String(),
      'end_of_scheduled_window': endOfScheduledWindow.toIso8601String(),
      'start_at': startAt.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'status': status.toDbString(),
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProfessionalAppointmentModel.fromMap(Map<String, dynamic> map) {
    final appointmentTime = map['appointment_time'] as Map<String, dynamic>?;
    final patient = map['patient'] as Map<String, dynamic>?;

    final dueAt = appointmentTime?['due_at']?.toString();
    final startTime = appointmentTime?['start_time_at']?.toString();
    final finishTime = appointmentTime?['finish_time_at']?.toString();
    final timezone = appointmentTime?['timezone']?.toString() ?? 'UTC';
    final startedAtStr = map['started_at']?.toString();
    final finishedAtStr = map['finished_at']?.toString();
    final statusStr = map['status']?.toString() ?? 'scheduled';

    final startOfScheduledWindow =
        map['start_of_scheduled_window'] != null
            ? DateTime.parse(map['start_of_scheduled_window']).toLocal()
            : _combineDateAndTime(dueAt, startTime);
    final endOfScheduledWindow = map['end_of_scheduled_window'] != null
        ? DateTime.parse(map['end_of_scheduled_window']).toLocal()
        : _combineNullableDateAndTime(dueAt, finishTime) ??
              _combineDateAndTime(dueAt, startTime)
                  .add(const Duration(hours: 1));
    final finishAt =
        _combineNullableDateAndTime(dueAt, finishTime) ?? endOfScheduledWindow;

    return ProfessionalAppointmentModel(
      id: map['id']?.toString() ?? '',
      scheduledBy: map['scheduled_by']?.toString() ?? '',
      professionalId: map['professional_id']?.toString() ?? '',
      patientId:
          patient?['id']?.toString() ?? map['scheduled_by']?.toString() ?? '',
      patientName: patient?['full_name']?.toString() ?? 'Paciente',
      patientImageUrl: patient?['image_url']?.toString(),
      patientPhone: patient?['phone']?.toString(),
      professionalType: map['professional_type']?.toString(),
      appointmentTimeId: map['appointment_time_id']?.toString() ?? '',
      startOfScheduledWindow: startOfScheduledWindow,
      endOfScheduledWindow: endOfScheduledWindow,
      startAt: startOfScheduledWindow,
      finishAt: finishAt,
      startedAt: startedAtStr != null
          ? DateTime.parse(startedAtStr).toLocal()
          : null,
      finishedAt: finishedAtStr != null
          ? DateTime.parse(finishedAtStr).toLocal()
          : null,
      status: AppointmentStatus.fromString(statusStr),
      timezone: timezone,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at']).toLocal()
          : DateTime.now(),

      professionalData: map['professional'] as Map<String, dynamic>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfessionalAppointmentModel.fromJson(String source) =>
      ProfessionalAppointmentModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  static DateTime _combineDateAndTime(String? dueAtStr, String? timeStr) {
    final dueAt = dueAtStr != null
        ? DateTime.parse(dueAtStr).toLocal()
        : DateTime.now();
    if (timeStr == null || timeStr.isEmpty) {
      return dueAt;
    }
    final parts = timeStr.split(':').map(int.parse).toList();
    final hour = parts.isNotEmpty ? parts[0] : 0;
    final minute = parts.length > 1 ? parts[1] : 0;
    final second = parts.length > 2 ? parts[2] : 0;

    return DateTime(dueAt.year, dueAt.month, dueAt.day, hour, minute, second);
  }

  static DateTime? _combineNullableDateAndTime(
    String? dueAtStr,
    String? timeStr,
  ) {
    if (timeStr == null || timeStr.isEmpty) {
      return null;
    }
    return _combineDateAndTime(dueAtStr, timeStr);
  }

  ProfessionalAppointmentModel copyWith({
    String? id,
    String? scheduledBy,
    String? professionalId,
    String? patientId,
    String? patientName,
    String? patientImageUrl,
    String? patientPhone,
    String? professionalType,
    String? appointmentTimeId,
    DateTime? startOfScheduledWindow,
    DateTime? endOfScheduledWindow,
    DateTime? startAt,
    DateTime? finishAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    AppointmentStatus? status,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfessionalAppointmentModel(
      id: id ?? this.id,
      scheduledBy: scheduledBy ?? this.scheduledBy,
      professionalId: professionalId ?? this.professionalId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImageUrl: patientImageUrl ?? this.patientImageUrl,
      patientPhone: patientPhone ?? this.patientPhone,
      professionalType: professionalType ?? this.professionalType,
      appointmentTimeId: appointmentTimeId ?? this.appointmentTimeId,
      startOfScheduledWindow:
          startOfScheduledWindow ?? this.startOfScheduledWindow,
      endOfScheduledWindow: endOfScheduledWindow ?? this.endOfScheduledWindow,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
