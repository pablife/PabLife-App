import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../infra/services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import 'rate_consultation_page.dart';

/// Pede a avaliação da sessão logo que o paciente volta ao app: a consulta
/// concluída mais recente dos últimos 7 dias, ainda sem nota. Se a pessoa
/// sair sem avaliar, não pergunta de novo sobre aquela sessão neste aparelho.
class RatingPrompt {
  RatingPrompt._();

  static const _dismissedKey = 'rating_prompt_dismissed';
  static const window = Duration(days: 7);
  static const _minInterval = Duration(minutes: 2);

  static DateTime? _lastCheck;
  static bool _open = false;

  /// A sessão a avaliar, ou null.
  static ProfessionalAppointmentModel? pick({
    required List<ProfessionalAppointmentModel> recent,
    required Set<String> rated,
    required Set<String> dismissed,
    required DateTime now,
  }) {
    final candidates =
        recent
            .where(
              (a) =>
                  a.status == AppointmentStatus.completed &&
                  !rated.contains(a.id) &&
                  !dismissed.contains(a.id) &&
                  a.startAt.isAfter(now.subtract(window)) &&
                  a.startAt.isBefore(now),
            )
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Confere e, se houver sessão para avaliar, abre "Como foi sua consulta?".
  /// Só abre por cima do Dashboard (não interrompe outra tela).
  static Future<void> maybeShow() async {
    if (_open) return;
    final now = DateTime.now();
    final last = _lastCheck;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastCheck = now;

    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        AppointmentRepository().getPatientAppointments(
          patientId: uid,
          startAt: now.subtract(window + const Duration(days: 1)),
          endAt: now,
        ),
        ConsultationRepository().ratedAppointmentIds(),
        _dismissed(),
      ]);
      final recent =
          (results[0] as dynamic).data as List<ProfessionalAppointmentModel>? ??
          const <ProfessionalAppointmentModel>[];
      final appointment = pick(
        recent: recent,
        rated: results[1] as Set<String>,
        dismissed: results[2] as Set<String>,
        now: now,
      );
      if (appointment == null || Get.currentRoute != DashboardPage.route) {
        return;
      }
      _open = true;
      final sent = await RateConsultationPage.open(appointment);
      if (!sent) await _dismiss(appointment.id);
    } catch (e) {
      debugPrint('Pedido de avaliação: $e');
    } finally {
      _open = false;
    }
  }

  static Future<Set<String>> _dismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_dismissedKey) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _dismiss(String appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_dismissedKey) ?? <String>[];
      if (!list.contains(appointmentId)) list.add(appointmentId);
      // Guarda só os últimos 50.
      final keep = list.length > 50 ? list.sublist(list.length - 50) : list;
      await prefs.setStringList(_dismissedKey, keep);
    } catch (_) {}
  }
}
