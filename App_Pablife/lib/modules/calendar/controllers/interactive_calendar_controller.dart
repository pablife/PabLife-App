import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pablife/infra/models/user_role.dart';
import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/services/auth_service.dart';
import '../repositories/calendar_repository.dart';

class InteractiveCalendarController extends GetxController {
  static InteractiveCalendarController get to =>
      Get.find<InteractiveCalendarController>();

  final CalendarRepository _repository = CalendarRepository();
  final AuthService _authService = AuthService();

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String expandedDateKey = '';
  List<Map<String, dynamic>> daysInMonth = [];
  bool isLoading = false;

  String? _professionalId;

  bool get isProfessional =>
      _authService.currentUser?.role == UserRole.professional;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (isProfessional) {
        _professionalId = await _repository.getProfessionalIdByUserId(
          userId: _authService.currentUser!.id!,
        );
      }

      await loadCalendarData();
    } catch (e) {
      debugPrint('❌ [InteractiveCalendarController] Erro ao inicializar: $e');
      isLoading = false;
      update();
    }
  }

  Future<void> loadCalendarData() async {
    try {
      isLoading = true;
      update();

      final startDate = DateTime(selectedYear, selectedMonth, 1);
      final endDate = DateTime(selectedYear, selectedMonth + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      if (isProfessional && _professionalId != null) {
        await _loadProfessionalCalendar(startDate, endDate);
      } else {
        await _loadPatientCalendar(startDateStr, endDateStr);
      }

      isLoading = false;
      update();
    } catch (e) {
      debugPrint(
        '❌ [InteractiveCalendarController] Erro ao carregar calendário: $e',
      );
      isLoading = false;
      update();
    }
  }

  Future<void> _loadPatientCalendar(String startDate, String endDate) async {
    try {
      final rows = await _repository.getPatientCalendarCounts(
        startDate: startDate,
        endDate: endDate,
      );

      _buildPatientDaysInMonth(rows);
    } catch (e) {
      debugPrint(
        '❌ [InteractiveCalendarController] Erro ao carregar calendário do paciente: $e',
      );
      rethrow;
    }
  }

  void _buildPatientDaysInMonth(List<Map<String, dynamic>> rows) {
    daysInMonth = [];

    for (final row in rows) {
      final dayDate = DateTime.parse(row['day_date'] as String);
      final taskCount = row['task_count'] as int? ?? 0;
      final noteCount = row['note_count'] as int? ?? 0;
      final appointmentCount = row['appointment_count'] as int? ?? 0;

      daysInMonth.add({
        'date': dayDate,
        'tasksCount': taskCount,
        'notesCount': noteCount,
        'appointmentsCount': appointmentCount,
        'appointments': <ProfessionalAppointmentModel>[],
        'availableSlotsCount': 0,
        'isProfessional': false,
      });
    }
  }

  Future<void> _loadProfessionalCalendar(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Buscar appointments e slots disponíveis em paralelo
      final results = await Future.wait([
        _repository.getProfessionalAppointments(
          professionalId: _professionalId!,
          startDate: startDate,
          endDate: endDate,
        ),
        _repository.getProfessionalAvailableSlots(
          professionalId: _professionalId!,
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      final appointments = results[0] as List<ProfessionalAppointmentModel>;
      final availableSlots = results[1] as List<ProfessionalScheduleSlot>;

      _buildProfessionalDaysInMonth(
        startDate,
        endDate,
        appointments,
        availableSlots,
      );
    } catch (e) {
      debugPrint(
        '❌ [InteractiveCalendarController] Erro ao carregar calendário do profissional: $e',
      );
      rethrow;
    }
  }

  void _buildProfessionalDaysInMonth(
    DateTime startDate,
    DateTime endDate,
    List<ProfessionalAppointmentModel> appointments,
    List<ProfessionalScheduleSlot> availableSlots,
  ) {
    final dayMap = <String, Map<String, dynamic>>{};

    // Inicializar todos os dias do mês
    for (int day = startDate.day; day <= endDate.day; day++) {
      final date = DateTime(selectedYear, selectedMonth, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      dayMap[dateKey] = {
        'date': date,
        'tasksCount': 0,
        'notesCount': 0,
        'appointmentsCount': 0,
        'availableSlots': <ProfessionalScheduleSlot>[],
        'appointments': <ProfessionalAppointmentModel>[],
        'isProfessional': true,
      };
    }

    // Preencher com appointments
    for (final appointment in appointments) {
      final dateKey = DateFormat('yyyy-MM-dd').format(appointment.startAt);

      if (dayMap.containsKey(dateKey)) {
        dayMap[dateKey]!['appointmentsCount'] =
            (dayMap[dateKey]!['appointmentsCount'] as int) + 1;
        (dayMap[dateKey]!['appointments'] as List<ProfessionalAppointmentModel>)
            .add(appointment);
      }
    }

    // Preencher com slots disponíveis
    for (final slot in availableSlots) {
      final dateKey = DateFormat('yyyy-MM-dd').format(slot.startAt.toLocal());

      if (dayMap.containsKey(dateKey)) {
        (dayMap[dateKey]!['availableSlots'] as List<ProfessionalScheduleSlot>)
            .add(slot);
      }
    }

    daysInMonth = dayMap.values.toList();
  }

  void changeMonth(DateTime newDate) {
    selectedYear = newDate.year;
    selectedMonth = newDate.month;
    expandedDateKey = '';
    loadCalendarData();
  }

  void toggleExpanded(String dateKey) {
    expandedDateKey = expandedDateKey == dateKey ? '' : dateKey;
    update();
  }
}
