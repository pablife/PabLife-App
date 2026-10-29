import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pablife/modules/home/controllers/user_home_controller.dart';

import '../../infra/models/activity_model.dart';
import '../../infra/repositories/activity_repository.dart';
import '../../infra/services/activity_service.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/dialogs/premium_lock_dialog.dart';
import 'pages/activity_details_page.dart';
import 'pages/interactive_calendar_page.dart';

enum CalendarFilter { todo, completed, all }

class CalendarItem {
  final String id;
  final String title;
  final String time;
  final int hour;
  final CalendarItemType type;
  final bool isCompleted;

  CalendarItem({
    required this.id,
    required this.title,
    required this.time,
    required this.hour,
    required this.type,
    this.isCompleted = false,
  });
}

enum CalendarItemType { task, taskPending, goal, note, consultation }

class CalendarController extends GetxController with LoaderManagerMixin {
  final ActivityService _activityService = ActivityService.instance;
  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;

  bool get canAccessPlanner => _authService.canAccessPlanner;

  bool get isInTrial => _authService.isInTrial;

  int? get trialDaysRemaining => _authService.trialDaysRemaining;

  CalendarFilter currentFilter = CalendarFilter.all;
  DateTime selectedDateTime = DateTime.now();
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
      final activityDate = activity?.activityDate ??
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

  List<CalendarItem> get allItems {
    return _activities.map((activity) {
      final dueAtLocal = activity.dueAt?.toLocal();
      final hour = dueAtLocal?.hour ?? 9;
      final minute = dueAtLocal?.minute ?? 0;
      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      CalendarItemType itemType;
      if (activity.type == 'goal') {
        itemType = CalendarItemType.goal;
      } else if (activity.type == 'note') {
        itemType = CalendarItemType.note;
      } else if (activity.type == 'appointment') {
        itemType = CalendarItemType.consultation;
      } else if (activity.type == 'task') {
        itemType = activity.isCompleted
            ? CalendarItemType.task
            : CalendarItemType.taskPending;
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

  void changeDate(DateTime date) {
    selectedDateTime = date;
    loadActivities();
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
    final items = allItems;

    if (items.isEmpty) return null;

    // Ordena todos os itens por hora e minuto
    items.sort((a, b) {
      final hourCompare = a.hour.compareTo(b.hour);
      if (hourCompare != 0) return hourCompare;
      final aMinute = int.tryParse(a.time.split(':')[1]) ?? 0;
      final bMinute = int.tryParse(b.time.split(':')[1]) ?? 0;
      return aMinute.compareTo(bMinute);
    });

    final firstUndone = items.firstWhereOrNull((item) => !item.isCompleted);

    if (firstUndone != null) {
      return firstUndone.hour;
    }

    return items.last.hour;
  }

  Future<void> toggleTaskStatus(String activityId, bool isCompleted) async {
    DateTime? activityDate;
    final activityIndex = _activities.indexWhere((a) => a.id == activityId);
    if (activityIndex != -1) {
      final activity = _activities[activityIndex];

      // Para goals, sempre usar o activityDate da meta (baseado no dueAt)
      // Para tasks/notes, pode usar a data selecionada no calendário
      if (activity.type == 'goal') {
        activityDate = activity.activityDate;
      } else {
        activityDate ??= activity.activityDate ??
            DateTime(
              selectedDateTime.year,
              selectedDateTime.month,
              selectedDateTime.day,
            );
      }

      final completedAt = isCompleted ? DateTime.now() : null;

      _activities[activityIndex] = activity.copyWith(
        isCompleted: isCompleted,
        completedAt: completedAt,
      );

      _pendingToggles[activityId] = isCompleted;

      update();
    }

    _toggleStatusDebounceTimer?.cancel();

    activityDate ??= DateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
    );

    _toggleStatusDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _sendToggleStatusToBackend(activityId, isCompleted, activityDate);
    });
  }

  Future<void> _sendToggleStatusToBackend(
    String activityId,
    bool isCompleted,
    DateTime? activityDate,
  ) async {
    if (activityDate == null) {
      AppSnackbar.to.show('Não foi possível identificar a data da atividade.');
      return;
    }
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

      AppSnackbar.to.show('Erro ao atualizar tarefa: ${e.toString()}');
    } finally {
      UserHomeController.to.refreshData();
    }
  }

  Future<void> createTask() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed('/calendar/task-editor');
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
      await loadActivities();
      UserHomeController.to.refreshData();
    }
  }

  Future<void> createGoal() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed('/calendar/goal-editor');
    if (result == true || result is Map<String, dynamic>) {
      await loadActivities();
      UserHomeController.to.refreshData();
    }
  }

  Future<void> createNote() async {
    await _authService.reloadUserAccessInfo();
    if (!canAccessPlanner) {
      _showAccessDeniedMessage();
      return;
    }
    final result = await Get.toNamed('/calendar/note-editor');
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
      await loadActivities();
      UserHomeController.to.refreshData();
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
}
