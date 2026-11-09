import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/models/professional_model.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/utils/app_snackbar.dart';
import 'appointment_outcome.dart';

/// Dados da área do profissional (Dashboard, Sala e Histórico): as consultas
/// do último ano e das próximas semanas, o link da sala e os registros.
class ProfessionalAreaController extends GetxController {
  static ProfessionalAreaController get to {
    if (!Get.isRegistered<ProfessionalAreaController>()) {
      Get.put(ProfessionalAreaController(), permanent: true);
    }
    return Get.find<ProfessionalAreaController>();
  }

  final _appointments = AppointmentRepository();
  final _professionals = ProfessionalRepository();
  final _consultations = ConsultationRepository();

  ProfessionalModel? professional;
  String? council;
  String? meetingUrl;
  List<ProfessionalAppointmentModel> appointments = [];
  int freeToday = 0;
  bool loading = true;
  String? registering;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  String get displayName {
    final user = AuthService.instance.currentUser;
    final preferred = user?.preferredName?.trim();
    return (preferred == null || preferred.isEmpty)
        ? (user?.fullName ?? '')
        : preferred;
  }

  String get roleLine {
    final type = professional?.type == 'nutritionist'
        ? 'Nutricionista'
        : 'Psicólogo(a)';
    return council == null ? type : '$type · $council';
  }

  Future<void> load() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    try {
      if (professional == null) {
        final response = await _professionals.getProfessionalByUserId(uid);
        professional = response.data;
      }
      final id = professional?.id;
      if (id == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        _appointments.getProfessionalAppointments(
          professionalId: id,
          startAt: today.subtract(const Duration(days: 365)),
          endAt: today.add(const Duration(days: 60)),
        ),
        _appointments.getProfessionalSlotsFromViewForDay(
          professionalId: id,
          date: today,
        ),
        _consultations.myMeetingUrl(id),
        _loadCouncil(id),
      ]);
      appointments =
          ((results[0] as dynamic).data as List?)
              ?.cast<ProfessionalAppointmentModel>() ??
          [];
      final slots = ((results[1] as dynamic).data as List?) ?? const [];
      freeToday = slots
          .where((s) => s.appointment == null && s.startAt.isAfter(now))
          .length;
      meetingUrl = results[2] as String?;
      council = results[3] as String?;
    } catch (e) {
      debugPrint('Área do profissional: $e');
    } finally {
      loading = false;
      update();
    }
  }

  Future<String?> _loadCouncil(String professionalId) async {
    try {
      final row = await Supabase.instance.client
          .from('tb_professionals')
          .select('council_number, council_region')
          .eq('id', professionalId)
          .maybeSingle();
      final number = row?['council_number']?.toString().trim() ?? '';
      if (number.isEmpty) return null;
      final region = row?['council_region']?.toString().trim() ?? '';
      final kind = professional?.type == 'nutritionist' ? 'CRN' : 'CRP';
      return region.isEmpty ? '$kind $number' : '$kind $region/$number';
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveMeetingUrl(String url) async {
    final id = professional?.id;
    if (id == null) return 'Perfil de profissional não encontrado.';
    final error = await _consultations.saveMeetingUrl(id, url);
    if (error == null) {
      meetingUrl = url.trim();
      update();
    }
    return error;
  }

  // ------------------------------------------------------------- consultas

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ProfessionalAppointmentModel> get today {
    final now = DateTime.now();
    return appointments
        .where((a) => _sameDay(a.startAt.toLocal(), now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// Próxima consulta marcada que ainda não terminou.
  ProfessionalAppointmentModel? get next {
    final now = DateTime.now();
    final list =
        appointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.scheduled &&
                  a.endOfScheduledWindow.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list.firstOrNull;
  }

  /// Consultas que já começaram e ainda estão como marcadas: falta registrar.
  List<ProfessionalAppointmentModel> get toRegister {
    final now = DateTime.now();
    return appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.scheduled &&
              a.startAt.isBefore(now),
        )
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  int get weekCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return appointments
        .where(
          (a) =>
              a.status != AppointmentStatus.cancelled &&
              !a.startAt.isBefore(start) &&
              a.startAt.isBefore(end),
        )
        .length;
  }

  /// Histórico: tudo que já teve um registro, do mais novo para o mais antigo.
  List<ProfessionalAppointmentModel> get history =>
      appointments.where((a) => AppointmentOutcome.of(a) != null).toList()
        ..sort((a, b) => b.startAt.compareTo(a.startAt));

  int get completedCount =>
      appointments.where((a) => a.status == AppointmentStatus.completed).length;

  int get patientsServed => appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .map((a) => a.patientId)
      .toSet()
      .length;

  /// Presença: realizadas sobre realizadas + faltas.
  int? get attendancePercent {
    final noShow = appointments
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;
    final total = completedCount + noShow;
    return total == 0 ? null : (completedCount * 100 / total).round();
  }

  /// Número da sessão com o paciente (1ª, 2ª…), contando as realizadas.
  int sessionNumber(ProfessionalAppointmentModel a) =>
      appointments
          .where(
            (b) =>
                b.patientId == a.patientId &&
                b.status == AppointmentStatus.completed &&
                b.startAt.isBefore(a.startAt),
          )
          .length +
      1;

  // ----------------------------------------------------------- registro

  /// Pergunta o que for preciso e registra. Devolve true quando gravou.
  Future<bool> register(
    BuildContext context,
    ProfessionalAppointmentModel appointment,
    AppointmentOutcome outcome,
  ) async {
    final reason = await askOutcomeReason(context, appointment, outcome);
    if (reason == null) return false;
    registering = appointment.id;
    update();
    final error = await _appointments.registerOutcome(
      appointmentId: appointment.id,
      outcome: outcome.value,
      reason: reason,
    );
    registering = null;
    if (error != null) {
      update();
      AppSnackbar.to.show(error);
      return false;
    }
    await load();
    AppSnackbar.to.show('Registrado: ${outcome.action.toLowerCase()}.');
    return true;
  }
}
