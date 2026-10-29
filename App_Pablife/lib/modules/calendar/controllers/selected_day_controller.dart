import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pablife/modules/calendar/pages/goal_editor_page.dart';
import 'package:pablife/modules/calendar/pages/note_editor_page.dart';
import 'package:pablife/modules/calendar/pages/task_editor_page.dart';
import 'package:pablife/modules/home/controllers/user_home_controller.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/activity_service.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/dialogs/premium_lock_dialog.dart';
import '../calendar_controller.dart';
import '../pages/activity_details_page.dart';

class SelectedDayController extends GetxController with LoaderManagerMixin {
  final ActivityService _activityService = ActivityService.instance;
  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;

  bool get canAccessPlanner => _authService.canAccessPlanner;

  bool get isInTrial => _authService.isInTrial;

  int? get trialDaysRemaining => _authService.trialDaysRemaining;

  CalendarFilter currentFilter = CalendarFilter.all;
  late DateTime selectedDateTime;
  List<ActivityModel> _activities = [];
  int? _scrollTargetHour;
  int _scrollTrigger = 0;

  Timer? _toggleStatusDebounceTimer;
  final Map<String, bool> _pendingToggles = {};

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

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is DateTime) {
      selectedDateTime = args;
    } else {
      selectedDateTime = DateTime.now();
    }
    loadActivities();
  }

  @override
  void onClose() {
    _toggleStatusDebounceTimer?.cancel();
    _flushPendingToggles();
    super.onClose();
  }

  void _flushPendingToggles() {
    if (_pendingToggles.isEmpty) return;

    final pendingIds = _pendingToggles.keys.toList();
    for (final id in pendingIds) {
      final isCompleted = _pendingToggles[id]!;
      final activity = _activities.firstWhereOrNull((a) => a.id == id);
      final activityDate =
          activity?.activityDate ??
          DateTime(
            selectedDateTime.year,
            selectedDateTime.month,
            selectedDateTime.day,
          );
      _sendToggleStatusToBackend(id, isCompleted, activityDate);
    }
  }

  Future<void> loadActivities() async {
    changeLoading(true);
    try {
      final response = await _activityRepository.loadActivitiesForDate(
        selectedDateTime,
      );

      if (response.success) {
        _activities =
            response.data?.map((activity) {
              if (_pendingToggles.containsKey(activity.id)) {
                final isCompleted = _pendingToggles[activity.id]!;
                return activity.copyWith(
                  isCompleted: isCompleted,
                  completedAt: isCompleted ? DateTime.now() : null,
                );
              }
              return activity;
            }).toList() ??
            [];
      } else {
        AppSnackbar.to.show('Erro ao carregar atividades: ${response.message}');
      }

      update();
    } finally {
      changeLoading(false);
    }
  }

  void removeActivityById(String activityId) {
    _activities.removeWhere((activity) => activity.id == activityId);
    _pendingToggles.remove(activityId);
    update();
  }

  List<CalendarItem> get allItems {
    return _activities.map((activity) {
      final hour = activity.dueAt?.hour ?? 9;
      final minute = activity.dueAt?.minute ?? 0;
      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      CalendarItemType itemType;
      if (activity.type == 'goal') {
        itemType = CalendarItemType.goal;
      } else if (activity.type == 'note') {
        itemType = CalendarItemType.note;
      } else if (activity.type == 'appointment') {
        itemType = CalendarItemType.consultation;
      } else if (activity.type == 'task' && !activity.isCompleted) {
        itemType = CalendarItemType.taskPending;
      } else {
        itemType = CalendarItemType.task;
      }

      return CalendarItem(
        id: activity.id,
        title: activity.name,
        time: timeStr,
        hour: hour,
        type: itemType,
        isCompleted: activity.isCompleted,
      );
    }).toList();
  }

  List<CalendarItem> get filteredItems {
    switch (currentFilter) {
      case CalendarFilter.todo:
        return allItems.where((item) => !item.isCompleted).toList();
      case CalendarFilter.completed:
        return allItems.where((item) => item.isCompleted).toList();
      case CalendarFilter.all:
        return allItems;
    }
  }

  int get tasksCount => _activities.where((a) => a.type == 'task').length;

  int get notesCount => _activities.where((a) => a.type == 'note').length;
  int? get scrollTargetHour => _scrollTargetHour;
  int get scrollTrigger => _scrollTrigger;

  void changeFilter(CalendarFilter filter) {
    currentFilter = filter;
    update();
  }

  void _setScrollToHour(int hour) {
    _scrollTargetHour = hour;
    _scrollTrigger += 1;
    update();
  }

  void clearScrollTarget() {
    _scrollTargetHour = null;
  }

  int? get highlightedHour {
    final tasks = allItems
        .where(
          (item) =>
              item.type == CalendarItemType.task ||
              item.type == CalendarItemType.taskPending,
        )
        .toList();

    if (tasks.isEmpty) return null;

    final now = DateTime.now();
    final isSameDay =
        selectedDateTime.year == now.year &&
        selectedDateTime.month == now.month &&
        selectedDateTime.day == now.day;

    if (isSameDay) {
      final currentHour = now.hour;
      final nextTask = tasks.where((t) => t.hour >= currentHour).toList();
      if (nextTask.isNotEmpty) {
        return nextTask.first.hour;
      }
      return tasks.last.hour;
    } else {
      return tasks.first.hour;
    }
  }

  Future<void> toggleTaskStatus(String id, bool isCompleted) async {
    final index = _activities.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final oldActivity = _activities[index];

    final activityDate = oldActivity.type == 'goal'
        ? oldActivity.activityDate
        : (oldActivity.activityDate ??
              DateTime(
                selectedDateTime.year,
                selectedDateTime.month,
                selectedDateTime.day,
              ));

    _activities[index] = oldActivity.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );

    _pendingToggles[id] = isCompleted;

    update();

    _toggleStatusDebounceTimer?.cancel();
    _toggleStatusDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      () => _sendToggleStatusToBackend(id, isCompleted, activityDate!),
    );
  }

  Future<void> _sendToggleStatusToBackend(
    String activityId,
    bool isCompleted,
    DateTime activityDate,
  ) async {
    try {
      final response = isCompleted
          ? await _activityRepository.markActivityAsCompleted(
              activityId,
              activityDate: activityDate,
            )
          : await _activityRepository.unmarkActivityAsCompleted(
              activityId,
              activityDate: activityDate,
            );

      if (response.success) {
        _pendingToggles.remove(activityId);
        await _activityService.refresh();
      } else {
        _pendingToggles.remove(activityId);

        final activityIndex = _activities.indexWhere((a) => a.id == activityId);
        if (activityIndex != -1) {
          final activity = _activities[activityIndex];
          _activities[activityIndex] = activity.copyWith(
            isCompleted: !isCompleted,
            completedAt: null,
          );
          update();
        }

        AppSnackbar.to.show(
          'Erro ao ${isCompleted ? 'marcar' : 'desmarcar'} tarefa: ${response.message}',
        );
      }
    } catch (e) {
      _pendingToggles.remove(activityId);

      final activityIndex = _activities.indexWhere((a) => a.id == activityId);
      if (activityIndex != -1) {
        final activity = _activities[activityIndex];
        _activities[activityIndex] = activity.copyWith(
          isCompleted: !isCompleted,
          completedAt: null,
        );
        update();
      }

      AppSnackbar.to.show('Erro ao atualizar status da atividade');
    } finally {
      UserHomeController.to.refreshData();
    }
  }

  Future<void> openActivityDetails(CalendarItem item) async {
    final activity = _activities.firstWhereOrNull((a) => a.id == item.id);
    if (activity != null) {
      final result = await Get.toNamed(
        ActivityDetailsPage.route,
        arguments: activity,
      );

      if (result == true || result is Map<String, dynamic>) {
        await loadActivities();
      }
    }
  }

  void createGoal() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed(
      GoalEditorPage.route,
      arguments: {'date': selectedDateTime},
    );
    if (result == true || result is Map<String, dynamic>) {
      loadActivities();
      Get.back(result: true);
    }
  }

  void createTask() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed(
      TaskEditorPage.route,
      arguments: {'date': selectedDateTime},
    );
    if (result is Map<String, dynamic> && result['dueAt'] is DateTime) {
      final dueAt = result['dueAt'] as DateTime;
      final isSameDay =
          selectedDateTime.year == dueAt.year &&
          selectedDateTime.month == dueAt.month &&
          selectedDateTime.day == dueAt.day;
      if (isSameDay) {
        _setScrollToHour(dueAt.hour);
      }
    }
    if (result == true || result is Map<String, dynamic>) {
      loadActivities();
      Get.back(result: true);
    }
  }

  void createNote() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed(
      NoteEditorPage.route,
      arguments: {'date': selectedDateTime},
    );
    if (result is Map<String, dynamic> && result['dueAt'] is DateTime) {
      final dueAt = result['dueAt'] as DateTime;
      final isSameDay =
          selectedDateTime.year == dueAt.year &&
          selectedDateTime.month == dueAt.month &&
          selectedDateTime.day == dueAt.day;
      if (isSameDay) {
        _setScrollToHour(dueAt.hour);
      }
    }
    if (result == true || result is Map<String, dynamic>) {
      loadActivities();
      Get.back(result: true);
    }
  }

  void _showAccessDeniedMessage() {
    Get.dialog(
      const PremiumLockDialog(
        message:
            'Você precisa de uma assinatura ativa ou período de trial para usar o Planner. '
            'Assine um plano para ter acesso!',
        contentType: 'Planner',
        contentTitle: 'Meu Planner',
      ),
    );
  }
}
