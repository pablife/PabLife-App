import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pablife/modules/calendar/controllers/interactive_calendar_controller.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/models/activity_model.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/services/activity_service.dart';
import '../../home/controllers/user_home_controller.dart';

class TaskEditorController extends GetxController with LoaderManagerMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;
  final ActivityService _activityService = ActivityService.instance;

  ActivityModel? _originalActivity;
  Map<String, dynamic>? _recurrenceRule;

  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedPriority;
  bool isRecurrenceEnabled = false;
  List<int> selectedWeekdays = [];
  bool isEditMode = false;

  bool get isRecurring =>
      _originalActivity?.activityRecurrenceRuleId != null && isRecurrenceEnabled;

  bool get showRecurrenceToggle => !isEditMode || isRecurring;

  bool get canToggleRecurrence => !isEditMode;

  bool get isDateLocked => isEditMode && isRecurring;

  static const List<Map<String, String>> priorityOptions = [
    {'value': 'low', 'label': 'Baixa'},
    {'value': 'medium', 'label': 'Média'},
    {'value': 'high', 'label': 'Alta'},
  ];

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map<String, dynamic> && args['activity'] is ActivityModel) {
      isEditMode = true;
      _originalActivity = args['activity'] as ActivityModel;
      _prefillFromActivity(_originalActivity!);
      if (_originalActivity!.activityRecurrenceRuleId != null) {
        isRecurrenceEnabled = true;
        _loadRecurrenceRule(_originalActivity!.activityRecurrenceRuleId!);
      } else {
        isRecurrenceEnabled = false;
      }
    } else if (args is Map<String, dynamic> && args['date'] != null) {
      selectedDate = args['date'] as DateTime;
    } else {
      selectedDate = DateTime.now();
    }

    selectedTime ??= TimeOfDay.now();
    selectedPriority ??= 'medium';
    _updateDateTimeFields();
  }

  @override
  void onClose() {
    nameController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.onClose();
  }

  void _updateDateTimeFields() {
    if (selectedDate != null) {
      dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
    }
    if (selectedTime != null) {
      if (selectedDate != null) {
        dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
      }
      timeController.text =
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      selectedDate = date;
      _updateDateTimeFields();
      update();
    }
  }

  Future<void> selectTime() async {
    final time = await showTimePicker(
      context: Get.context!,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      selectedTime = time;
      _updateDateTimeFields();
      update();
    }
  }

  void toggleRecurrence() {
    if (isEditMode) return;
    isRecurrenceEnabled = !isRecurrenceEnabled;
    if (!isRecurrenceEnabled) {
      selectedWeekdays.clear();
    }
    update();
  }

  void toggleWeekday(int index) {
    if (isEditMode && !isRecurring) return;
    if (selectedWeekdays.contains(index)) {
      selectedWeekdays.remove(index);
    } else {
      selectedWeekdays.add(index);
    }
    update();
  }

  Future<void> saveTask() async {
    if (isEditMode) {
      await _saveTaskEdits();
      return;
    }

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a tarefa');
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      AppSnackbar.to.show('Por favor, selecione data e horário');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      AppSnackbar.to.show('Usuário não autenticado');
      return;
    }

    changeLoading(true);

    try {
      // Cria o datetime local
      final localDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Converte para UTC usando timezone
      final localTZ = tz.TZDateTime.from(localDateTime, tz.local);
      final utcDateTime = tz.TZDateTime.from(localTZ, tz.UTC);
      final dueDateTime = DateTime.utc(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
      );

      if (selectedPriority == null) {
        AppSnackbar.to.show('Por favor, selecione uma prioridade');
        changeLoading(false);
        return;
      }

      String? recurrenceRuleId;

      if (isRecurrenceEnabled && selectedWeekdays.isNotEmpty) {
        final dbWeekdays = selectedWeekdays.map((uiIndex) {
          if (uiIndex == 6) {
            return 0;
          } else {
            return uiIndex + 1;
          }
        }).toList();

        final recurrenceResponse = await _activityRepository
            .createRecurrenceRule(
              startAt: dueDateTime,
              byWeekDay: dbWeekdays,
              weekStart: 0,
            );

        if (recurrenceResponse.success) {
          recurrenceRuleId = recurrenceResponse.data;
        } else {
          changeLoading(false);
          AppSnackbar.to.show(
            'Erro ao criar recorrência: ${recurrenceResponse.message}',
          );
          return;
        }
      }

      final timezoneName = tz.local.name;

      final activity = ActivityModel(
        id: '',
        userId: userId,
        type: 'task',
        name: nameController.text.trim(),
        description: null,
        priority: selectedPriority!,
        dueAt: recurrenceRuleId != null ? null : dueDateTime,
        allDay: false,
        timezone: timezoneName,
        activityRecurrenceRuleId: recurrenceRuleId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _activityRepository.createActivity(activity);

      if (response.success && response.data != null) {
        _activityService.addActivity(response.data!);
        _activityService.refresh();

        try {
          final homeController = Get.find<UserHomeController>();
          await homeController.refreshData();
        } catch (e) {
          //
        }

        try {
          await InteractiveCalendarController.to.loadCalendarData();
        } catch (e) {
          //
        }

        changeLoading(false);
        Get.back(result: {'dueAt': localDateTime});
        AppSnackbar.to.show('Tarefa criada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao criar tarefa: ${e.toString()}');
    }
  }

  void _prefillFromActivity(ActivityModel activity) {
    nameController.text = activity.name;
    selectedPriority = activity.priority;

    final dueAtLocal = activity.dueAt?.toLocal();
    if (dueAtLocal != null) {
      selectedDate = DateTime(
        dueAtLocal.year,
        dueAtLocal.month,
        dueAtLocal.day,
      );
      selectedTime = TimeOfDay.fromDateTime(dueAtLocal);
    } else if (activity.activityDate != null) {
      selectedDate = activity.activityDate;
      selectedTime ??= TimeOfDay.now();
    } else {
      selectedDate = DateTime.now();
      selectedTime ??= TimeOfDay.now();
    }

    _updateDateTimeFields();
  }

  Future<void> _loadRecurrenceRule(String recurrenceRuleId) async {
    final response =
        await _activityRepository.getRecurrenceRuleById(recurrenceRuleId);
    if (!response.success || response.data == null) {
      AppSnackbar.to.show('Não foi possível carregar a recorrência.');
      return;
    }

    _recurrenceRule = response.data;

    final ruleStartAt = _recurrenceRule?['start_at'] as String?;
    if (ruleStartAt != null) {
      final parsedStartAt = DateTime.parse(ruleStartAt);
      final localStart = tz.TZDateTime.from(parsedStartAt, tz.local);
      selectedTime = TimeOfDay.fromDateTime(localStart);
      selectedDate ??= DateTime(localStart.year, localStart.month, localStart.day);
    }

    final dbWeekdays =
        List<int>.from(_recurrenceRule?['by_week_day'] ?? const <int>[]);
    selectedWeekdays = dbWeekdays
        .map((dbDay) => dbDay == 0 ? 6 : dbDay - 1)
        .toList();

    _updateDateTimeFields();
    update();
  }

  List<int> _mapUiWeekdaysToDb(List<int> uiWeekdays) {
    return uiWeekdays.map((uiIndex) {
      if (uiIndex == 6) {
        return 0;
      }
      return uiIndex + 1;
    }).toList();
  }

  DateTime _buildRecurringStartAt(TimeOfDay time) {
    final ruleStartAt = _recurrenceRule?['start_at'] as String?;
    DateTime baseDate = DateTime.now();
    if (ruleStartAt != null) {
      final parsedStartAt = DateTime.parse(ruleStartAt);
      final localStart = tz.TZDateTime.from(parsedStartAt, tz.local);
      baseDate = DateTime(localStart.year, localStart.month, localStart.day);
    }

    final localDateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );

    final localTZ = tz.TZDateTime.from(localDateTime, tz.local);
    final utcDateTime = tz.TZDateTime.from(localTZ, tz.UTC);
    return DateTime.utc(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
      utcDateTime.hour,
      utcDateTime.minute,
    );
  }

  Future<void> _saveTaskEdits() async {
    if (_originalActivity == null) return;

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a tarefa');
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      AppSnackbar.to.show('Por favor, selecione data e horário');
      return;
    }

    if (selectedPriority == null) {
      AppSnackbar.to.show('Por favor, selecione uma prioridade');
      return;
    }

    changeLoading(true);

    try {
      final localDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final localTZ = tz.TZDateTime.from(localDateTime, tz.local);
      final utcDateTime = tz.TZDateTime.from(localTZ, tz.UTC);
      final dueDateTime = DateTime.utc(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
      );

      if (isRecurring) {
        if (_recurrenceRule == null) {
          AppSnackbar.to.show('Recorrência não carregada.');
          changeLoading(false);
          return;
        }
        if (selectedWeekdays.isEmpty) {
          AppSnackbar.to.show('Selecione ao menos um dia da semana.');
          changeLoading(false);
          return;
        }

        final dbWeekdays = _mapUiWeekdaysToDb(selectedWeekdays);
        final newStartAt = _buildRecurringStartAt(selectedTime!);
        final timezoneName = tz.local.name;

        final recurrenceResponse = await _activityRepository.updateRecurrenceRule(
          recurrenceRuleId: _originalActivity!.activityRecurrenceRuleId!,
          startAt: newStartAt,
          byWeekDay: dbWeekdays,
          weekStart: 0,
          timezone: timezoneName,
        );

        if (!recurrenceResponse.success) {
          changeLoading(false);
          AppSnackbar.to.show(recurrenceResponse.message);
          return;
        }
      }

      // Cria um novo ActivityModel ao invés de usar copyWith
      // porque copyWith não aceita null corretamente (usa ?? que mantém valor original)
      final updatedActivity = ActivityModel(
        id: _originalActivity!.id,
        userId: _originalActivity!.userId,
        type: _originalActivity!.type,
        name: nameController.text.trim(),
        description: _originalActivity!.description,
        steps: _originalActivity!.steps,
        priority: selectedPriority!,
        dueAt: isRecurring ? null : dueDateTime,
        allDay: _originalActivity!.allDay,
        timezone: tz.local.name,
        activityRecurrenceRuleId: _originalActivity!.activityRecurrenceRuleId,
        createdAt: _originalActivity!.createdAt,
        updatedAt: DateTime.now(),
      );

      final updateResponse =
          await _activityRepository.updateActivity(updatedActivity);

      if (updateResponse.success && updateResponse.data != null) {
        _activityService.updateActivity(updateResponse.data!);
        await _activityService.refresh();

        try {
          final homeController = Get.find<UserHomeController>();
          await homeController.refreshData();
        } catch (e) {
          //
        }

        try {
          await InteractiveCalendarController.to.loadCalendarData();
        } catch (e) {
          //
        }

        changeLoading(false);
        Get.back(result: {'dueAt': localDateTime});
        AppSnackbar.to.show('Tarefa atualizada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(updateResponse.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao atualizar tarefa: ${e.toString()}');
    }
  }

  void onPriorityChanged(String? priority) {
    selectedPriority = priority;
    update();
  }

  void goBack() {
    Get.back();
  }
}
