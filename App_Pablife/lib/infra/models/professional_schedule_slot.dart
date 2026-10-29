import 'package:intl/intl.dart';

import 'professional_appointment_model.dart';

class ProfessionalScheduleSlot {
  ProfessionalScheduleSlot({
    required this.id,
    required this.professionalId,
    required this.startAt,
    required this.finishAt,
    required this.timezone,
    this.appointmentRecurrenceRuleId,
    this.appointment,
  });

  final String id;
  final String professionalId;
  final DateTime startAt;
  final DateTime finishAt;
  final String timezone;
  final String? appointmentRecurrenceRuleId;
  final ProfessionalAppointmentModel? appointment;

  bool get hasAppointment => appointment != null;
  bool get isRecurring => appointmentRecurrenceRuleId != null;

  bool get isPast => finishAt.isBefore(DateTime.now());

  bool get isCurrent {
    final now = DateTime.now();
    return startAt.isBefore(now) && finishAt.isAfter(now);
  }

  bool get isFuture => startAt.isAfter(DateTime.now());

  String get timeLabel => DateFormat('HH:mm').format(startAt.toLocal());

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'professional_id': professionalId,
      'start_at': startAt.toIso8601String(),
      'finish_at': finishAt.toIso8601String(),
      'timezone': timezone,
      'appointment_recurrence_rule_id': appointmentRecurrenceRuleId,
      'appointment': appointment?.toMap(),
    };
  }

  factory ProfessionalScheduleSlot.fromMap(Map<String, dynamic> map) {
    ProfessionalAppointmentModel? appointment;
    final dynamic appointmentRaw = map['appointment'];
    if (appointmentRaw != null) {
      if (appointmentRaw is Map<String, dynamic>) {
        if (appointmentRaw.isNotEmpty) {
          appointment = ProfessionalAppointmentModel.fromMap(appointmentRaw);
        }
      } else if (appointmentRaw is List && appointmentRaw.isNotEmpty) {
        final first = appointmentRaw.first;
        if (first is Map<String, dynamic>) {
          appointment = ProfessionalAppointmentModel.fromMap(first);
        }
      }
    }

    final dueAt = map['due_at']?.toString();
    final startTime = map['start_time_at']?.toString();
    final finishTime = map['finish_time_at']?.toString();
    final timezone = map['timezone']?.toString() ?? 'UTC';

    return ProfessionalScheduleSlot(
      id: map['id']?.toString() ?? '',
      professionalId: map['professional_id']?.toString() ?? '',
      startAt: _combineDateAndTime(dueAt, startTime),
      finishAt: _combineDateAndTime(dueAt, finishTime),
      timezone: timezone,
      appointmentRecurrenceRuleId:
          map['appointment_recurrence_rule_id']?.toString(),
      appointment: appointment,
    );
  }

  factory ProfessionalScheduleSlot.fromViewMap(Map<String, dynamic> map) {
    final isMyAppointment = map['is_my_appointment'] == true;
    final slotStartAt = _parseDateTime(map['slot_start_at']);
    final slotFinishAt = _parseDateTime(map['slot_finish_at']);
    final timezone = map['timezone']?.toString() ?? 'America/Sao_Paulo';

    ProfessionalAppointmentModel? appointment;
    if (isMyAppointment) {
      appointment = ProfessionalAppointmentModel(
        id: map['appointment_time_id']?.toString() ?? '',
        scheduledBy: '',
        professionalId: map['professional_id']?.toString() ?? '',
        patientId: '',
        patientName: 'Paciente',
        patientImageUrl: null,
        patientPhone: null,
        appointmentTimeId: map['appointment_time_id']?.toString() ?? '',
        startOfScheduledWindow: slotStartAt,
        endOfScheduledWindow: slotFinishAt,
        startAt: slotStartAt,
        finishAt: slotFinishAt,
        status: AppointmentStatus.scheduled,
        timezone: timezone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return ProfessionalScheduleSlot(
      id: map['appointment_time_id']?.toString() ?? '',
      professionalId: map['professional_id']?.toString() ?? '',
      startAt: slotStartAt,
      finishAt: slotFinishAt,
      timezone: timezone,
      appointmentRecurrenceRuleId:
          map['appointment_recurrence_rule_id']?.toString(),
      appointment: appointment,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) {
      return value.isUtc ? value.toLocal() : value;
    }

    final str = value.toString();
    final isUtc =
        str.contains('Z') ||
        str.contains('+00') ||
        (str.contains('+') && str.length > 19);

    if (isUtc) {
      return DateTime.parse(str).toLocal();
    }

    return DateTime.parse(str);
  }

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

  ProfessionalScheduleSlot copyWith({
    String? id,
    String? professionalId,
    DateTime? startAt,
    DateTime? finishAt,
    String? timezone,
    String? appointmentRecurrenceRuleId,
    ProfessionalAppointmentModel? appointment,
  }) {
    return ProfessionalScheduleSlot(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      timezone: timezone ?? this.timezone,
      appointmentRecurrenceRuleId:
          appointmentRecurrenceRuleId ?? this.appointmentRecurrenceRuleId,
      appointment: appointment ?? this.appointment,
    );
  }

  @override
  String toString() {
    return '${startAt.toLocal().hour}:${startAt.toLocal().minute} - ${finishAt.toLocal().hour}:${finishAt.toLocal().minute}';
  }
}
