import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../../widgets/design_system/text_default.dart';
import '../pages/interactive_calendar_page.dart';
import '../widgets/create_schedule_slot_bottom_sheet.dart';
import 'interactive_calendar_controller.dart';

enum ProfessionalAgendaFilter { todo, completed, all }

class ProfessionalCalendarController extends GetxController
    with LoaderManagerMixin {
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final AuthService _authService = AuthService.instance;

  ProfessionalAgendaFilter currentFilter = ProfessionalAgendaFilter.all;
  DateTime selectedDateTime = DateTime.now();
  List<ProfessionalScheduleSlot> _slots = [];
  String? _professionalId;
  bool _didLogNoAppointments = false;
  int? _scrollTargetHour;
  int _scrollTrigger = 0;

  @override
  void onInit() {
    super.onInit();
    _loadProfessional();
  }

  Future<void> _loadProfessional() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final response = await _professionalRepository.getProfessionalByUserId(
      userId,
    );
    if (response.success && response.data != null) {
      _professionalId = response.data!.id;
      await loadDailySchedule();
    } else {
      _slots = [];
      update();
    }
  }

  Future<void> loadDailySchedule() async {
    final professionalId = _professionalId;
    if (professionalId == null) {
      debugPrint('❌ [ProfessionalCalendar] Professional ID é null');
      return;
    }

    debugPrint(
      '📅 [ProfessionalCalendar] Carregando agenda para: $professionalId',
    );
    debugPrint('📅 [ProfessionalCalendar] Data selecionada: $selectedDateTime');

    changeLoading(true);
    try {
      final startOfDay = DateTime(
        selectedDateTime.year,
        selectedDateTime.month,
        selectedDateTime.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final slotsResponse = await _appointmentRepository
          .getProfessionalSlotsFromViewForDay(
            professionalId: professionalId,
            date: selectedDateTime,
          );

      final appointmentsResponse = await _appointmentRepository
          .getProfessionalAppointments(
            professionalId: professionalId,
            startAt: startOfDay,
            endAt: endOfDay,
          );

      final List<ProfessionalScheduleSlot> availableSlots =
          slotsResponse.success && slotsResponse.data != null
          ? slotsResponse.data!
          : <ProfessionalScheduleSlot>[];

      final List<ProfessionalAppointmentModel> appointments =
          appointmentsResponse.success && appointmentsResponse.data != null
          ? appointmentsResponse.data!
          : <ProfessionalAppointmentModel>[];

      debugPrint(
        '📅 [ProfessionalCalendar] ${availableSlots.length} slots disponíveis',
      );
      debugPrint(
        '📅 [ProfessionalCalendar] ${appointments.length} consultas marcadas',
      );

      final occupiedSlotIds = appointments
          .map((a) => a.appointmentTimeId)
          .where((id) => id.isNotEmpty)
          .toSet();

      final freeSlots = availableSlots
          .where((slot) => !occupiedSlotIds.contains(slot.id))
          .toList();

      debugPrint('📅 [ProfessionalCalendar] ${freeSlots.length} slots livres');

      final appointmentSlots = appointments.map((appointment) {
        final effectiveFinish =
            appointment.finishedAt ??
            appointment.finishAt ??
            appointment.startAt.add(const Duration(hours: 1));

        return ProfessionalScheduleSlot(
          id: appointment.appointmentTimeId.isNotEmpty
              ? appointment.appointmentTimeId
              : appointment.id,
          professionalId: appointment.professionalId,
          startAt: appointment.startAt,
          finishAt: effectiveFinish,
          timezone: appointment.timezone,
          appointment: appointment,
        );
      }).toList();

      final combinedSlots = [...freeSlots, ...appointmentSlots];
      combinedSlots.sort((a, b) => a.startAt.compareTo(b.startAt));

      _slots = combinedSlots;
      debugPrint(
        '✅ [ProfessionalCalendar] ${_slots.length} slots finais na agenda',
      );
      _didLogNoAppointments = false;
    } finally {
      changeLoading(false);
      update();
    }
  }

  void changeDate(DateTime date) {
    selectedDateTime = date;
    loadDailySchedule();
  }

  void _setScrollToHour(int hour) {
    _scrollTargetHour = hour;
    _scrollTrigger += 1;
    update();
  }

  void clearScrollTarget() {
    _scrollTargetHour = null;
  }

  Future<void> openInteractiveCalendar() async {
    final result = await Get.toNamed(
      InteractiveCalendarPage.route,
      arguments: {
        'year': selectedDateTime.year,
        'month': selectedDateTime.month,
      },
    );

    if (result != null && result is DateTime) {
      changeDate(result);
    }
  }

  void changeFilter(ProfessionalAgendaFilter filter) {
    currentFilter = filter;
    update();
  }

  List<ProfessionalScheduleSlot> get slots => _slots;

  List<ProfessionalScheduleSlot> get filteredSlots {
    switch (currentFilter) {
      case ProfessionalAgendaFilter.todo:
        return _slots.where((slot) {
          if (slot.hasAppointment) {
            return !slot.appointment!.isCompleted;
          }
          return slot.isFuture;
        }).toList();
      case ProfessionalAgendaFilter.completed:
        return _slots
            .where((slot) => slot.appointment?.isCompleted ?? false)
            .toList();
      case ProfessionalAgendaFilter.all:
        return _slots;
    }
  }

  int get scheduledCount => _slots.where((slot) => slot.hasAppointment).length;

  int get availableCount => _slots.where((slot) => !slot.hasAppointment).length;
  int? get scrollTargetHour => _scrollTargetHour;
  int get scrollTrigger => _scrollTrigger;

  String get selectedDate {
    return DateFormat('dd.MM').format(selectedDateTime);
  }

  String get selectedMonth {
    final months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return months[selectedDateTime.month - 1];
  }

  String get selectedWeekday {
    final weekdays = [
      'Segunda Feira',
      'Terça Feira',
      'Quarta Feira',
      'Quinta Feira',
      'Sexta Feira',
      'Sábado',
      'Domingo',
    ];
    return weekdays[selectedDateTime.weekday - 1];
  }

  int? get highlightedHour {
    final slotsWithAppointments = _slots
        .where((slot) => slot.hasAppointment)
        .toList();
    if (slotsWithAppointments.isEmpty) {
      if (!_didLogNoAppointments) {
        debugPrint(
          'ℹ️ [ProfessionalCalendar] Nenhuma consulta para destacar no dia ${DateFormat('yyyy-MM-dd').format(selectedDateTime)}.',
        );
        _didLogNoAppointments = true;
      }
      return null;
    }

    final upcomingSlot = slotsWithAppointments.firstWhereOrNull(
      (slot) => !slot.appointment!.isCompleted,
    );

    if (upcomingSlot != null) {
      final hour = upcomingSlot.startAt.toLocal().hour;
      debugPrint('✅ [ProfessionalCalendar] Hora destacada (futura): ${hour}h');
      return hour;
    }

    final hour = slotsWithAppointments.first.startAt.toLocal().hour;
    debugPrint('✅ [ProfessionalCalendar] Hora destacada (primeira): ${hour}h');
    return hour;
  }

  Future<void> openCreateScheduleSlotBottomSheet() async {
    final professionalId = _professionalId;
    if (professionalId == null) {
      AppSnackbar.to.show('Profissional não encontrado');
      return;
    }

    final result = await CreateScheduleSlotBottomSheet.show<dynamic>(
      Get.context!,
      professionalId,
    );

    if (result == null || result == 'cancelled') {
      return;
    }

    if (result is Map<String, dynamic>) {
      final dateTime = result['dateTime'] as DateTime?;
      final isRecurring = result['isRecurring'] as bool? ?? false;

      if (dateTime != null) {
        await _createScheduleSlot(dateTime, isRecurring);
      }
    }
  }

  Future<void> _createScheduleSlot(DateTime startAt, bool isRecurring) async {
    final professionalId = _professionalId;
    if (professionalId == null) {
      AppSnackbar.to.show('Profissional não encontrado');
      return;
    }

    debugPrint('📅 [ProfessionalCalendar] Criando horário: $startAt');
    debugPrint(
      '📅 [ProfessionalCalendar] Data selecionada atual: $selectedDateTime',
    );

    changeLoading(true);
    final wasSameDay =
        selectedDateTime.year == startAt.year &&
        selectedDateTime.month == startAt.month &&
        selectedDateTime.day == startAt.day;
    try {
      if (isRecurring) {
        final response = await _professionalRepository
            .createRecurringScheduleSlot(
          professionalId: professionalId,
          startAt: startAt,
          duration: const Duration(hours: 1),
        );

        if (response.success) {
          AppSnackbar.to.show('Horário recorrente criado com sucesso!');
        } else {
          AppSnackbar.to.show(response.message);
          return;
        }
      } else {
        final response = await _professionalRepository.createScheduleSlot(
          professionalId: professionalId,
          startAt: startAt,
          duration: const Duration(hours: 1),
        );

        if (response.success) {
          debugPrint('✅ [ProfessionalCalendar] Horário criado com sucesso');
          AppSnackbar.to.show('Horário criado com sucesso!');
        } else {
          AppSnackbar.to.show(response.message);
          return;
        }
      }

      final createdDateLocal = DateTime(
        startAt.year,
        startAt.month,
        startAt.day,
      );

      debugPrint(
        '📅 [ProfessionalCalendar] Data do horário criado (local): $createdDateLocal',
      );
      debugPrint(
        '📅 [ProfessionalCalendar] Data selecionada atual: $selectedDateTime',
      );

      if (createdDateLocal.year != selectedDateTime.year ||
          createdDateLocal.month != selectedDateTime.month ||
          createdDateLocal.day != selectedDateTime.day) {
        debugPrint(
          '📅 [ProfessionalCalendar] Atualizando data selecionada para: $createdDateLocal',
        );
        selectedDateTime = createdDateLocal;
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      debugPrint('📅 [ProfessionalCalendar] Recarregando agenda...');
      await loadDailySchedule();
      if (wasSameDay) {
        _setScrollToHour(startAt.toLocal().hour);
      }
      await _refreshInteractiveCalendarIfSameMonth(createdDateLocal);
    } finally {
      changeLoading(false);
    }
  }

  Future<void> promptRemoveSlot(ProfessionalScheduleSlot slot) async {
    if (slot.hasAppointment) {
      return;
    }

    final isRecurring = slot.isRecurring;
    bool applyToFuture = false;

    final result = await showDialog<bool?>(
      context: Get.context!,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppDialog(
              title: isRecurring
                  ? 'Remover horário recorrente'
                  : 'Remover horário',
              content: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextDefault(
                      isRecurring
                          ? 'Este horário se repete semanalmente. Você pode remover apenas este dia ou encerrar a recorrência para os próximos horários.'
                          : 'Tem certeza que deseja remover este horário? Esta ação não pode ser desfeita.',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(204),
                      textAlign: TextAlign.center,
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: applyToFuture,
                            onChanged: (value) {
                              setState(() {
                                applyToFuture = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFFF5252),
                            checkColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextDefault(
                              'Aplicar para todos os horários futuros',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              confirmText: 'Remover',
              cancelText: 'Cancelar',
              confirmButtonColor: const Color(0xFFFF5252),
              cancelButtonColor: const Color(0xFF0C8DA1),
              onConfirm: () => Navigator.of(context).pop(applyToFuture),
              onCancel: () => Navigator.of(context).pop(null),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    changeLoading(true);
    try {
      final normalizedDate = DateTime(
        slot.startAt.year,
        slot.startAt.month,
        slot.startAt.day,
      );
      final response = await _professionalRepository.removeScheduleSlot(
        appointmentTimeId: slot.id,
        slotDate: normalizedDate,
        applyToFuture: isRecurring ? result : false,
      );

      if (response.success) {
        AppSnackbar.to.show('Horário removido com sucesso!');
        await loadDailySchedule();
        await _refreshInteractiveCalendarIfSameMonth(slot.startAt.toLocal());
      } else {
        AppSnackbar.to.show(response.message);
      }
    } finally {
      changeLoading(false);
    }
  }

  Future<void> _refreshInteractiveCalendarIfSameMonth(
    DateTime affectedDate,
  ) async {
    if (!Get.isRegistered<InteractiveCalendarController>()) {
      return;
    }

    final interactiveController = Get.find<InteractiveCalendarController>();
    if (interactiveController.selectedYear != affectedDate.year ||
        interactiveController.selectedMonth != affectedDate.month) {
      return;
    }

    await interactiveController.loadCalendarData();
  }
}
