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
import '../pages/goal_suggestions_page.dart';
import 'interactive_calendar_controller.dart';

class GoalEditorController extends GetxController with LoaderManagerMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;
  final ActivityService _activityService = ActivityService.instance;

  ActivityModel? _originalActivity;
  bool isEditMode = false;

  final nameController = TextEditingController();
  final deadlineController = TextEditingController();
  final strategyController = TextEditingController();

  final List<TextEditingController> stepControllers = [];

  DateTime? selectedDeadline;
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
    DateTime baseDate;
    if (args is Map<String, dynamic> && args['activity'] is ActivityModel) {
      isEditMode = true;
      _originalActivity = args['activity'] as ActivityModel;
      _prefillFromActivity(_originalActivity!);
      baseDate = selectedDeadline ?? DateTime.now();
    } else if (args is Map<String, dynamic> && args['date'] != null) {
      baseDate = args['date'] as DateTime;
    } else {
      baseDate = DateTime.now();
    }

    selectedDeadline ??= baseDate;
    selectedPriority ??= 'medium';
    _updateDeadlineField();
    _initStepControllers();
  }

  @override
  void onClose() {
    nameController.dispose();
    deadlineController.dispose();
    strategyController.dispose();
    for (final controller in stepControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  void _updateDeadlineField() {
    if (selectedDeadline != null) {
      deadlineController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(selectedDeadline!);
    }
  }

  Future<void> selectDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDeadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );

    if (date != null) {
      selectedDeadline = date;
      _updateDeadlineField();
      update();
    }
  }

  void _initStepControllers() {
    if (stepControllers.isEmpty) {
      stepControllers.add(TextEditingController());
    }
  }

  void onStepsChanged() {
    update();
  }

  bool get canAddAnotherStep =>
      stepControllers.isNotEmpty &&
      stepControllers.every((c) => c.text.trim().isNotEmpty);

  void addStepField() {
    if (!canAddAnotherStep) return;
    stepControllers.add(TextEditingController());
    update();
  }

  Future<void> showGoalSuggestions() async {
    final result = await Get.toNamed(GoalSuggestionsPage.route);
    if (result != null && result is Map<String, dynamic>) {
      _populateFieldsFromSuggestion(result);
    }
  }

  void _populateFieldsFromSuggestion(Map<String, dynamic> suggestion) {
    nameController.text = suggestion['title'] ?? '';

    final duration = suggestion['duration'] ?? '6 meses';
    final months = _parseDurationToMonths(duration);
    selectedDeadline = DateTime.now().add(Duration(days: months * 30));
    _updateDeadlineField();

    strategyController.text = suggestion['description'] ?? '';

    // Usa a prioridade da sugestão ou 'medium' como padrão
    selectedPriority = suggestion['priority'] ?? 'medium';

    // Preenche etapas a partir da sugestao
    for (final controller in stepControllers) {
      controller.dispose();
    }
    stepControllers.clear();

    if (suggestion['steps'] != null && suggestion['steps'] is List) {
      for (final step in List<String>.from(suggestion['steps'])) {
        stepControllers.add(TextEditingController(text: step));
      }
    }

    _initStepControllers();

    update();
  }

  int _parseDurationToMonths(String duration) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(duration);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '6') ?? 6;
    }
    return 6;
  }

  Future<void> saveGoal() async {
    if (isEditMode) {
      await _saveGoalEdits();
      return;
    }

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a meta');
      return;
    }

    if (selectedDeadline == null) {
      AppSnackbar.to.show('Por favor, selecione um prazo final');
      return;
    }

    if (selectedPriority == null) {
      AppSnackbar.to.show('Por favor, selecione uma prioridade');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      AppSnackbar.to.show('Usuário não autenticado');
      return;
    }

    changeLoading(true);

    try {
      final localDateTime = DateTime(
        selectedDeadline!.year,
        selectedDeadline!.month,
        selectedDeadline!.day,
        23,
        59,
        59,
      );

      final localTZ = tz.TZDateTime.from(localDateTime, tz.local);
      final utcDateTime = tz.TZDateTime.from(localTZ, tz.UTC);
      final dueDateTime = DateTime.utc(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
        utcDateTime.second,
      );

      final timezoneName = tz.local.name;

      final activity = ActivityModel(
        id: '',
        userId: userId,
        type: 'goal',
        name: nameController.text.trim(),
        description: strategyController.text.trim(),
        steps: stepControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
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
        AppSnackbar.to.show('Meta criada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao criar meta: ${e.toString()}');
    }
  }

  void _prefillFromActivity(ActivityModel activity) {
    nameController.text = activity.name;
    strategyController.text = activity.description ?? '';
    selectedPriority = activity.priority;

    final dueAtLocal = activity.dueAt?.toLocal();
    if (dueAtLocal != null) {
      selectedDeadline = DateTime(
        dueAtLocal.year,
        dueAtLocal.month,
        dueAtLocal.day,
      );
    }

    for (final controller in stepControllers) {
      controller.dispose();
    }
    stepControllers.clear();

    final steps = activity.steps ?? [];
    if (steps.isNotEmpty) {
      for (final step in steps) {
        stepControllers.add(TextEditingController(text: step));
      }
    }

    _initStepControllers();
    _updateDeadlineField();
  }

  Future<void> _saveGoalEdits() async {
    if (_originalActivity == null) return;

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.to.show('Por favor, insira um nome para a meta');
      return;
    }

    if (selectedDeadline == null) {
      AppSnackbar.to.show('Por favor, selecione um prazo final');
      return;
    }

    if (selectedPriority == null) {
      AppSnackbar.to.show('Por favor, selecione uma prioridade');
      return;
    }

    changeLoading(true);

    try {
      final localDateTime = DateTime(
        selectedDeadline!.year,
        selectedDeadline!.month,
        selectedDeadline!.day,
        23,
        59,
        59,
      );

      final localTZ = tz.TZDateTime.from(localDateTime, tz.local);
      final utcDateTime = tz.TZDateTime.from(localTZ, tz.UTC);
      final dueDateTime = DateTime.utc(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
        utcDateTime.second,
      );

      final updatedActivity = _originalActivity!.copyWith(
        name: nameController.text.trim(),
        description: strategyController.text.trim(),
        steps: stepControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
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
        AppSnackbar.to.show('Meta atualizada com sucesso!');
      } else {
        changeLoading(false);
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao atualizar meta: ${e.toString()}');
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
