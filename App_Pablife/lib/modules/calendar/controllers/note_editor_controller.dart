import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/models/activity_model.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/services/activity_service.dart';
import '../../home/controllers/user_home_controller.dart';
import 'interactive_calendar_controller.dart';

class NoteEditorController extends GetxController with LoaderManagerMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;
  final ActivityService _activityService = ActivityService.instance;

  ActivityModel? _originalActivity;
  bool isEditMode = false;

  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedPriority;

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

  Future<void> saveNote() async {
    if (isEditMode) {
      await _saveNoteEdits();
      return;
    }

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a anotação');
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

      final timezoneName = tz.local.name;

      final activity = ActivityModel(
        id: '',
        userId: userId,
        type: 'note',
        name: nameController.text.trim(),
        description: null,
        priority: selectedPriority!,
        dueAt: dueDateTime,
        allDay: false,
        timezone: timezoneName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _activityRepository.createActivity(activity);

      if (response.success && response.data != null) {
        _activityService.addActivity(response.data!);
        _activityService.refresh();

        try {
          final homeController = Get.find<UserHomeController>();
          homeController.refreshData();
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
        AppSnackbar.to.show('Anotação criada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao criar anotação: ${e.toString()}');
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
    } else {
      selectedDate = DateTime.now();
      selectedTime ??= TimeOfDay.now();
    }

    _updateDateTimeFields();
  }

  Future<void> _saveNoteEdits() async {
    if (_originalActivity == null) return;

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a anotação');
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

      final updatedActivity = _originalActivity!.copyWith(
        name: nameController.text.trim(),
        priority: selectedPriority!,
        dueAt: dueDateTime,
        timezone: tz.local.name,
        updatedAt: DateTime.now(),
      );

      final response = await _activityRepository.updateActivity(updatedActivity);

      if (response.success && response.data != null) {
        _activityService.updateActivity(response.data!);
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
        AppSnackbar.to.show('Anotação atualizada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao atualizar anotação: ${e.toString()}');
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
