import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/pab_colors.dart';
import '../../widgets/design_system/app_image.dart';

/// Dados da consulta já prontos para as telas (nome, profissão, datas).
extension ConsultationInfo on ProfessionalAppointmentModel {
  Map<String, dynamic>? get _user =>
      professionalData?['user'] as Map<String, dynamic>?;

  String get professionalName =>
      _user?['full_name']?.toString() ?? 'Profissional';

  String? get professionalImage => _user?['image_url']?.toString();

  String get professionalPhone => _user?['phone']?.toString() ?? '';

  String get professionalRole {
    final type = professionalData?['type'] ?? professionalType;
    return switch (type) {
      'psychologist' => 'Psicólogo(a)',
      'nutritionist' => 'Nutricionista',
      _ => 'Profissional',
    };
  }

  String get professionalInitials => professionalName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.length > 2)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  String get statusLabel => switch (status) {
    AppointmentStatus.scheduled => 'Confirmada',
    AppointmentStatus.completed => 'Realizada',
    AppointmentStatus.cancelled => 'Cancelada',
    AppointmentStatus.noShow => 'Não compareceu',
    AppointmentStatus.technicalIssue => 'Problema técnico',
  };

  DateTime get localStart => startAt.toLocal();

  /// "Seg, 9 de nov · 16:00"
  String get shortWhen {
    final s = localStart;
    final day = DateFormat("EEE, d 'de' MMM", 'pt_BR').format(s);
    final clean = day.replaceAll('.', '');
    return '${clean[0].toUpperCase()}${clean.substring(1)} · '
        '${DateFormat('HH:mm').format(s)}';
  }

  /// "Segunda-feira, 9 de novembro"
  String get longDay {
    final d = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(localStart);
    return '${d[0].toUpperCase()}${d.substring(1)}';
  }

  String get time => DateFormat('HH:mm').format(localStart);

  DateTime get localEnd =>
      (finishAt ?? startAt.add(const Duration(hours: 1))).toLocal();

  /// A sala abre 15 minutos antes e fecha no fim da consulta (igual ao
  /// banco).
  bool roomOpen([DateTime? now]) {
    final n = now ?? DateTime.now();
    return status == AppointmentStatus.scheduled &&
        !n.isBefore(localStart.subtract(const Duration(minutes: 15))) &&
        !n.isAfter(localEnd);
  }
}

/// Foto do profissional, ou as iniciais num círculo lilás.
class ProfessionalAvatarCircle extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;
  final double size;

  const ProfessionalAvatarCircle({
    super.key,
    required this.appointment,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: PabColors.lilac,
      alignment: Alignment.center,
      child: Text(
        appointment.professionalInitials,
        style: TextStyle(
          fontSize: size * .3,
          fontWeight: FontWeight.w800,
          color: PabColors.lilacText,
        ),
      ),
    );
    return ClipOval(
      child: AppImage(
        imageUrl: appointment.professionalImage,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: fallback,
      ),
    );
  }
}
