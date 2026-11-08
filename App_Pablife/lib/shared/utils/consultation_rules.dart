import '../../infra/models/professional_appointment_model.dart';

/// Prazos de remarcar e cancelar, os mesmos que o banco confere
/// (migração 20261109100000_consultation_rules).
///
/// Consultas marcadas a partir da data de corte seguem as regras novas:
/// remarcar até 3 horas antes; cancelar até a hora da consulta, mas com menos
/// de 24 horas ela não volta para o saldo. As marcadas antes seguem a regra
/// antiga: remarcar e cancelar até 24 horas antes.
abstract final class ConsultationRules {
  /// 9 de novembro de 2026, 0h em Fortaleza.
  static final DateTime cutoff = DateTime.utc(2026, 11, 9, 3);

  static bool followsNewRules(ProfessionalAppointmentModel appointment) =>
      !appointment.createdAt.toUtc().isBefore(cutoff);

  static Duration rescheduleLimit(ProfessionalAppointmentModel appointment) =>
      followsNewRules(appointment)
      ? const Duration(hours: 3)
      : const Duration(hours: 24);

  static bool canReschedule(
    ProfessionalAppointmentModel appointment, {
    DateTime? now,
  }) =>
      appointment.status == AppointmentStatus.scheduled &&
      appointment.startAt.isAfter(
        (now ?? DateTime.now()).add(rescheduleLimit(appointment)),
      );

  static bool canCancel(
    ProfessionalAppointmentModel appointment, {
    DateTime? now,
  }) {
    if (appointment.status != AppointmentStatus.scheduled) return false;
    final current = now ?? DateTime.now();
    return followsNewRules(appointment)
        ? appointment.startAt.isAfter(current)
        : appointment.startAt.isAfter(current.add(const Duration(hours: 24)));
  }

  /// Cancelar agora devolve a consulta ao saldo?
  static bool cancelReturnsToBalance(
    ProfessionalAppointmentModel appointment, {
    DateTime? now,
  }) =>
      !followsNewRules(appointment) ||
      appointment.startAt.isAfter(
        (now ?? DateTime.now()).add(const Duration(hours: 24)),
      );

  /// Texto curto com os prazos, para mostrar perto dos botões.
  static String limitsText(ProfessionalAppointmentModel appointment) =>
      followsNewRules(appointment)
      ? 'Você pode remarcar até 3 horas antes. Cancelando com menos de 24 '
            'horas, a consulta não volta para o seu saldo.'
      : 'Remarcar e cancelar ficam disponíveis até 24 horas antes da consulta.';
}
