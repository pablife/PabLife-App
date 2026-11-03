import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../appointment_details/appointment_details_routes.dart';
import '../repositories/calendar_repository.dart';
import 'professional_calendar_controller.dart';

enum WideAgendaView { week, month, year }

/// Agenda do profissional no computador (semana, mês e ano, no estilo do
/// Google Agenda). Criar e remover horários reaproveita o
/// [ProfessionalCalendarController], o mesmo da agenda do celular.
class ProfessionalWideCalendarController extends GetxController
    with LoaderManagerMixin {
  final CalendarRepository _calendarRepository = CalendarRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final AuthService _authService = AuthService.instance;

  static const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  WideAgendaView view = WideAgendaView.week;
  DateTime focusDate = _dateOnly(DateTime.now());

  /// Caixas "Mostrar" da coluna da esquerda.
  bool showAppointments = true;
  bool showFree = true;

  String? _professionalId;
  Map<DateTime, List<ProfessionalScheduleSlot>> _slotsByDay = {};
  int _loadToken = 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    _professionalId = await _calendarRepository.getProfessionalIdByUserId(
      userId: userId,
    );
    await load();
  }

  // ---------------------------------------------------------------- período

  /// Primeiro dia mostrado (inclusive).
  DateTime get rangeStart {
    switch (view) {
      case WideAgendaView.week:
        return weekStart(focusDate);
      case WideAgendaView.month:
        return weekStart(DateTime(focusDate.year, focusDate.month, 1));
      case WideAgendaView.year:
        return DateTime(focusDate.year, 1, 1);
    }
  }

  /// Dia seguinte ao último mostrado (exclusive).
  DateTime get rangeEnd {
    switch (view) {
      case WideAgendaView.week:
        return rangeStart.add(const Duration(days: 7));
      case WideAgendaView.month:
        return rangeStart.add(const Duration(days: 42));
      case WideAgendaView.year:
        return DateTime(focusDate.year + 1, 1, 1);
    }
  }

  /// A semana começa no domingo, como no Google Agenda.
  static DateTime weekStart(DateTime day) =>
      _dateOnly(day).subtract(Duration(days: day.weekday % 7));

  List<DateTime> get weekDays => List.generate(
    7,
    (i) => DateTime(rangeStart.year, rangeStart.month, rangeStart.day + i),
  );

  String get title {
    switch (view) {
      case WideAgendaView.week:
        final start = rangeStart;
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${monthNames[start.month - 1]} de ${start.year}';
        }
        final a = monthNames[start.month - 1].substring(0, 3);
        final b = monthNames[end.month - 1].substring(0, 3);
        return start.year == end.year
            ? '$a – $b de ${end.year}'
            : '$a de ${start.year} – $b de ${end.year}';
      case WideAgendaView.month:
        return '${monthNames[focusDate.month - 1]} de ${focusDate.year}';
      case WideAgendaView.year:
        return '${focusDate.year}';
    }
  }

  // ---------------------------------------------------------------- dados

  Future<void> load() async {
    final professionalId = _professionalId;
    if (professionalId == null) return;

    final token = ++_loadToken;
    final start = rangeStart;
    final end = rangeEnd;
    changeLoading(true);
    try {
      // As duas buscas correm ao mesmo tempo.
      final slotsFuture = _calendarRepository.getProfessionalAvailableSlots(
        professionalId: professionalId,
        startDate: start,
        endDate: end.subtract(const Duration(days: 1)),
      );
      final appointmentsFuture = _appointmentRepository
          .getProfessionalAppointments(
            professionalId: professionalId,
            startAt: start,
            endAt: end,
          );
      final slots = await slotsFuture;
      final appointmentsResponse = await appointmentsFuture;
      // Se o usuário trocou de período durante a busca, descarta.
      if (token != _loadToken) return;

      final appointments = appointmentsResponse.success
          ? appointmentsResponse.data ?? <ProfessionalAppointmentModel>[]
          : <ProfessionalAppointmentModel>[];

      _slotsByDay = _groupByDay(slots, appointments);
    } catch (e) {
      debugPrint('❌ [WideCalendar] Erro ao carregar agenda: $e');
      if (token == _loadToken) _slotsByDay = {};
    } finally {
      if (token == _loadToken) {
        changeLoading(false);
        update();
      }
    }
  }

  /// Junta horários livres e consultas, como na agenda do dia: um horário
  /// que já tem consulta aparece só como consulta.
  Map<DateTime, List<ProfessionalScheduleSlot>> _groupByDay(
    List<ProfessionalScheduleSlot> slots,
    List<ProfessionalAppointmentModel> appointments,
  ) {
    final occupied = appointments
        .map((a) => a.appointmentTimeId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final all = <ProfessionalScheduleSlot>[
      ...slots.where((s) => !occupied.contains(s.id)),
      ...appointments.map(
        (a) => ProfessionalScheduleSlot(
          id: a.appointmentTimeId.isNotEmpty ? a.appointmentTimeId : a.id,
          professionalId: a.professionalId,
          startAt: a.startAt,
          finishAt:
              a.finishedAt ??
              a.finishAt ??
              a.startAt.add(const Duration(hours: 1)),
          timezone: a.timezone,
          appointment: a,
        ),
      ),
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));

    final byDay = <DateTime, List<ProfessionalScheduleSlot>>{};
    for (final slot in all) {
      byDay.putIfAbsent(_dateOnly(slot.startAt.toLocal()), () => []).add(slot);
    }
    return byDay;
  }

  /// Itens do dia, respeitando as caixas "Mostrar".
  List<ProfessionalScheduleSlot> slotsOn(DateTime day) {
    final slots = _slotsByDay[_dateOnly(day)] ?? const [];
    return slots
        .where((s) => s.hasAppointment ? showAppointments : showFree)
        .toList();
  }

  int appointmentCountOn(DateTime day) =>
      (_slotsByDay[_dateOnly(day)] ?? []).where((s) => s.hasAppointment).length;

  int freeCountOn(DateTime day) => (_slotsByDay[_dateOnly(day)] ?? [])
      .where((s) => !s.hasAppointment)
      .length;

  /// Totais do período mostrado (para as caixas "Mostrar").
  int get appointmentCount =>
      _slotsByDay.values.expand((s) => s).where((s) => s.hasAppointment).length;

  int get freeCount => _slotsByDay.values
      .expand((s) => s)
      .where((s) => !s.hasAppointment)
      .length;

  // ---------------------------------------------------------------- navegação

  void setView(WideAgendaView newView) {
    if (view == newView) return;
    view = newView;
    update();
    load();
  }

  void goToday() {
    focusDate = _dateOnly(DateTime.now());
    update();
    load();
  }

  void move(int direction) {
    switch (view) {
      case WideAgendaView.week:
        focusDate = focusDate.add(Duration(days: 7 * direction));
      case WideAgendaView.month:
        focusDate = DateTime(focusDate.year, focusDate.month + direction, 1);
      case WideAgendaView.year:
        focusDate = DateTime(focusDate.year + direction, focusDate.month, 1);
    }
    update();
    load();
  }

  /// Clique num dia (minicalendário, mês ou ano): abre a semana desse dia.
  void openDay(DateTime day) {
    focusDate = _dateOnly(day);
    view = WideAgendaView.week;
    update();
    load();
  }

  void toggleAppointments(bool value) {
    showAppointments = value;
    update();
  }

  void toggleFree(bool value) {
    showFree = value;
    update();
  }

  // ---------------------------------------------------------------- ações

  ProfessionalCalendarController get _slotActions =>
      Get.find<ProfessionalCalendarController>();

  /// Libera um horário (botão "+ Novo horário" ou clique num espaço vazio).
  Future<void> createSlot({DateTime? at}) async {
    final created = await _slotActions.openCreateScheduleSlotBottomSheet(
      initialDateTime: at,
    );
    if (created) await load();
  }

  Future<void> removeSlot(ProfessionalScheduleSlot slot) async {
    final removed = await _slotActions.promptRemoveSlot(slot);
    if (removed) await load();
  }

  void openAppointment(ProfessionalAppointmentModel appointment) {
    Get.toNamed(
      AppointmentDetailsRoutes.appointmentDetails,
      arguments: appointment.id,
    )?.then((_) => load());
  }
}
