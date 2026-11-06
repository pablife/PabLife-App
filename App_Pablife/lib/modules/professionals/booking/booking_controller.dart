import 'package:get/get.dart';

import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/models/professional_with_user_model.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../women_health/women_health_controller.dart';
import '../../women_health/women_health_data.dart';

enum BookingStep { pick, confirm, done }

/// Período do dia, para agrupar os horários.
class BookingPeriod {
  final String name;
  final String range;
  final int startHour;
  final int endHour;
  final List<ProfessionalScheduleSlot> slots;

  const BookingPeriod(
    this.name,
    this.range,
    this.startHour,
    this.endHour,
    this.slots,
  );
}

/// Agendamento em uma tela só: dias com horário à vista, horários separados
/// por período e confirmação.
class BookingController extends GetxController {
  final ProfessionalWithUserModel professional;
  final Future<List<ProfessionalScheduleSlot>> Function() _loadSlots;

  /// Devolve a mensagem de erro, ou null se a consulta foi marcada.
  final Future<String?> Function(ProfessionalScheduleSlot slot) _book;
  final DateTime Function() _now;
  final void Function(String message) _notify;

  /// Modo Saúde da mulher ativo: muda os textos e mostra o ciclo.
  final bool womenMode;
  final WomenCyclePhase? Function(DateTime day)? _cyclePhaseOn;

  BookingController({
    required this.professional,
    required Future<List<ProfessionalScheduleSlot>> Function() loadSlots,
    required Future<String?> Function(ProfessionalScheduleSlot slot) book,
    DateTime Function()? now,
    void Function(String message)? notify,
    this.womenMode = false,
    WomenCyclePhase? Function(DateTime day)? cyclePhaseOn,
  }) : _loadSlots = loadSlots,
       _book = book,
       _now = now ?? DateTime.now,
       _notify = notify ?? AppSnackbar.to.show,
       _cyclePhaseOn = cyclePhaseOn;

  factory BookingController.live(ProfessionalWithUserModel professional) {
    final appointments = AppointmentRepository();
    final professionals = ProfessionalRepository();
    final women = Get.isRegistered<WomenHealthController>()
        ? WomenHealthController.to
        : null;
    final womenMode = women?.isActive ?? false;
    final hasCycle =
        womenMode &&
        (women?.trail == WomenTrail.cycle ||
            women?.trail == WomenTrail.conceive) &&
        women?.lastPeriod != null;

    return BookingController(
      professional: professional,
      womenMode: womenMode,
      cyclePhaseOn: hasCycle ? women?.cyclePhaseOn : null,
      loadSlots: () async {
        final response = await appointments.getProfessionalSlotsFromView(
          professionalId: professional.professional.id!,
          date: DateTime.now(),
        );
        if (!response.success) throw Exception(response.message);
        return response.data ?? [];
      },
      book: (slot) async {
        final response = await professionals.scheduleAppointment(
          professionalId: professional.professional.id!,
          appointmentTimeId: slot.id,
          slotStartAt: slot.startAt,
        );
        if (!response.success) return response.message;
        await AuthService.instance.reloadUserAccessInfo();
        return null;
      },
    );
  }

  BookingStep step = BookingStep.pick;
  bool loading = true;
  bool loadFailed = false;
  bool booking = false;
  bool showCycle = true;
  bool monthOpen = false;

  /// Horários livres por dia, em ordem.
  Map<DateTime, List<ProfessionalScheduleSlot>> slotsByDay = {};

  late DateTime viewMonth;
  DateTime? selectedDay;
  ProfessionalScheduleSlot? selectedSlot;

  DateTime get today => _dateOnly(_now());

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool get hasCycle => _cyclePhaseOn != null;

  WomenCyclePhase? cyclePhaseOn(DateTime day) => _cyclePhaseOn?.call(day);

  /// Fase mostrada no calendário, se a pessoa deixou o ciclo visível.
  WomenCyclePhase? visibleCyclePhaseOn(DateTime day) =>
      showCycle ? cyclePhaseOn(day) : null;

  List<ProfessionalScheduleSlot> slotsOn(DateTime day) =>
      slotsByDay[_dateOnly(day)] ?? const [];

  List<ProfessionalScheduleSlot> get selectedDaySlots =>
      selectedDay == null ? const [] : slotsOn(selectedDay!);

  ProfessionalScheduleSlot? get firstSlot =>
      slotsByDay.isEmpty ? null : slotsByDay.values.first.first;

  bool get hasAnySlot => slotsByDay.isNotEmpty;

  /// Agrupa os horários do dia escolhido, sem os períodos vazios.
  List<BookingPeriod> get periods {
    const groups = [
      ('Manhã', 'até 12h', 0, 12),
      ('Tarde', '12h às 18h', 12, 18),
      ('Noite', 'a partir das 18h', 18, 24),
    ];
    return [
      for (final (name, range, start, end) in groups)
        BookingPeriod(name, range, start, end, [
          for (final slot in selectedDaySlots)
            if (slot.startAt.hour >= start && slot.startAt.hour < end) slot,
        ]),
    ].where((period) => period.slots.isNotEmpty).toList();
  }

  bool get canGoPrevMonth =>
      viewMonth.isAfter(DateTime(today.year, today.month));

  /// Os horários livres vão até 180 dias à frente.
  bool get canGoNextMonth {
    final last = today.add(const Duration(days: 180));
    return viewMonth.isBefore(DateTime(last.year, last.month));
  }

  @override
  void onInit() {
    super.onInit();
    viewMonth = DateTime(today.year, today.month);
    load();
  }

  Future<void> load() async {
    loading = true;
    loadFailed = false;
    update();
    try {
      final now = _now();
      final grouped = <DateTime, List<ProfessionalScheduleSlot>>{};
      final seen = <DateTime>{};
      final slots = await _loadSlots();
      slots.sort((a, b) => a.startAt.compareTo(b.startAt));
      for (final slot in slots) {
        if (!slot.startAt.isAfter(now) || !seen.add(slot.startAt)) continue;
        grouped.putIfAbsent(_dateOnly(slot.startAt), () => []).add(slot);
      }
      slotsByDay = grouped;

      final kept = selectedDay != null && slotsByDay.containsKey(selectedDay);
      if (!kept && hasAnySlot) _showDay(slotsByDay.keys.first);
    } catch (_) {
      loadFailed = true;
    }
    loading = false;
    update();
  }

  void _showDay(DateTime day) {
    selectedDay = day;
    selectedSlot = null;
    viewMonth = DateTime(day.year, day.month);
  }

  void selectDay(DateTime day) {
    if (slotsOn(day).isEmpty) return;
    _showDay(_dateOnly(day));
    update();
  }

  void selectSlot(ProfessionalScheduleSlot slot) {
    selectedSlot = slot;
    update();
  }

  void useFirstSlot() {
    final slot = firstSlot;
    if (slot == null) return;
    _showDay(_dateOnly(slot.startAt));
    selectedSlot = slot;
    update();
  }

  void goToNextDayWithSlots() {
    final from = selectedDay ?? today;
    for (final day in slotsByDay.keys) {
      if (day.isAfter(from)) {
        selectDay(day);
        return;
      }
    }
    if (hasAnySlot) selectDay(slotsByDay.keys.first);
  }

  void changeMonth(int delta) {
    if (delta < 0 && !canGoPrevMonth) return;
    if (delta > 0 && !canGoNextMonth) return;
    viewMonth = DateTime(viewMonth.year, viewMonth.month + delta);
    update();
  }

  void toggleMonth() {
    monthOpen = !monthOpen;
    update();
  }

  void toggleCycle() {
    showCycle = !showCycle;
    update();
  }

  void toConfirm() {
    if (selectedSlot == null) return;
    step = BookingStep.confirm;
    update();
  }

  void backToPick() {
    step = BookingStep.pick;
    update();
  }

  Future<void> confirm() async {
    final slot = selectedSlot;
    if (slot == null || booking) return;
    booking = true;
    update();

    String? error;
    try {
      error = await _book(slot);
    } catch (_) {
      error = 'Não foi possível agendar. Tente novamente.';
    }
    booking = false;

    if (error == null) {
      step = BookingStep.done;
      update();
      return;
    }

    _notify(error);
    // Alguém pode ter marcado este horário antes: mostra o que restou.
    selectedSlot = null;
    step = BookingStep.pick;
    update();
    await load();
  }
}
