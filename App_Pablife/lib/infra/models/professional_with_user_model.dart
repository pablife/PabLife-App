import 'dart:convert';
import 'professional_model.dart';
import 'user_model.dart';

class ProfessionalWithUserModel {
  final ProfessionalModel professional;
  final UserModel user;

  final DateTime? appointmentDate;
  final String? appointmentTime;
  final String? appointmentId;
  final String? appointmentTimeId;
  final String? appointmentTimezone;

  ProfessionalWithUserModel({
    required this.professional,
    required this.user,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentId,
    this.appointmentTimeId,
    this.appointmentTimezone,
  });

  String get typeFormatted {
    switch (professional.type) {
      case 'psychologist':
        return 'Psicólogo';
      case 'nutritionist':
        return 'Nutricionista';
      default:
        return professional.type;
    }
  }

  bool get hasAppointment =>
      appointmentDate != null &&
      appointmentTime != null &&
      appointmentId != null;

  String? get appointmentFormatted {
    if (!hasAppointment) return null;

    final day = appointmentDate!.day.toString().padLeft(2, '0');
    final month = appointmentDate!.month.toString().padLeft(2, '0');
    final year = appointmentDate!.year;

    return '$day/$month/$year às $appointmentTime';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'professional': professional.toMap(),
      'user': user.toMap(),
      'appointment_date': appointmentDate?.toIso8601String(),
      'appointment_time': appointmentTime,
      'appointment_id': appointmentId,
      'appointment_time_id': appointmentTimeId,
      'appointment_timezone': appointmentTimezone,
    };
  }

  factory ProfessionalWithUserModel.fromMap(Map<String, dynamic> map) {
    return ProfessionalWithUserModel(
      professional: ProfessionalModel.fromMap(map['professional']),
      user: UserModel.fromMap(map['user']),
      appointmentDate: map['appointment_date'] != null
          ? DateTime.parse(map['appointment_date'])
          : null,
      appointmentTime: map['appointment_time'],
      appointmentId: map['appointment_id'],
      appointmentTimeId: map['appointment_time_id'],
      appointmentTimezone: map['appointment_timezone'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfessionalWithUserModel.fromJson(String source) =>
      ProfessionalWithUserModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  ProfessionalWithUserModel copyWith({
    ProfessionalModel? professional,
    UserModel? user,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? appointmentId,
    String? appointmentTimeId,
    String? appointmentTimezone,
    bool clearAppointment = false,
  }) {
    return ProfessionalWithUserModel(
      professional: professional ?? this.professional,
      user: user ?? this.user,
      appointmentDate: clearAppointment
          ? null
          : (appointmentDate ?? this.appointmentDate),
      appointmentTime: clearAppointment
          ? null
          : (appointmentTime ?? this.appointmentTime),
      appointmentId: clearAppointment
          ? null
          : (appointmentId ?? this.appointmentId),
      appointmentTimeId: clearAppointment
          ? null
          : (appointmentTimeId ?? this.appointmentTimeId),
      appointmentTimezone: clearAppointment
          ? null
          : (appointmentTimezone ?? this.appointmentTimezone),
    );
  }
}
