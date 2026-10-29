import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/activity_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../calendar_controller.dart';
import 'selected_day_controller.dart';
import 'interactive_calendar_controller.dart';
import '../../home/controllers/user_home_controller.dart';

class ActivityDetailsController extends GetxController with LoaderManagerMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final ActivityService _activityService = ActivityService.instance;

  ActivityModel? activity;
  ActivityModel? _initialActivity;

  @override
  void onInit() {
    super.onInit();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      isLoading = true;
      update();

      final args = Get.arguments;
      String? activityId;

      if (args is String) {
        activityId = args;
      } else if (args is ActivityModel) {
        activityId = args.id;
        _initialActivity = args;
      } else if (args is Map && args['activity'] is ActivityModel) {
        final argActivity = args['activity'] as ActivityModel;
        activityId = argActivity.id;
        _initialActivity = argActivity;
      } else if (args is Map && args['id'] != null) {
        activityId = args['id'];
      }

      if (activityId == null) {
        throw Exception('ID da atividade não fornecido');
      }

      final response = await _activityRepository.getActivityById(activityId);

      if (!response.success || response.data == null) {
        throw Exception('Atividade não encontrada');
      }

      if (_initialActivity != null) {
        final base = response.data!;
        activity = base.copyWith(
          dueAt: base.dueAt ?? _initialActivity!.dueAt,
          eventDate: _initialActivity!.eventDate ?? base.eventDate,
          isCompleted: _initialActivity!.isCompleted,
          completedAt: _initialActivity!.completedAt,
        );
      } else {
        activity = response.data;
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao carregar atividade: $e');
      Get.back();
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> promptDeleteActivity() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Excluir Atividade',
      message:
          'Tem certeza que deseja excluir esta atividade? Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      confirmButtonColor: const Color(0xFFFF5252),
    );

    if (confirmed == true) {
      await deleteActivity();
    }
  }

  Future<void> deleteActivity() async {
    changeLoading(true);
    try {
      final response = await _activityRepository.deleteActivity(activity!.id);
      if (response.success) {
        _activityService.removeActivity(activity!.id);
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

        try {
          if (Get.isRegistered<SelectedDayController>()) {
            Get.find<SelectedDayController>().removeActivityById(activity!.id);
          }
        } catch (e) {
          //
        }

        try {
          final calendarController = Get.find<CalendarController>();
          await calendarController.loadActivities();
        } catch (e) {
          //
        }

        Get.back(result: true);
        AppSnackbar.to.show('Atividade excluída com sucesso');
      } else {
        AppSnackbar.to.show('Erro ao excluir atividade: ${response.message}');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao excluir atividade: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  Future<void> editActivity() async {
    if (activity == null) return;

    String route;
    switch (activity!.type) {
      case 'task':
        route = '/calendar/task-editor';
        break;
      case 'goal':
        route = '/calendar/goal-editor';
        break;
      case 'note':
        route = '/calendar/note-editor';
        break;
      default:
        route = '/calendar/task-editor';
    }

    final result = await Get.toNamed(
      route,
      arguments: {'activity': activity},
    );

    if (result is Map<String, dynamic> && result['dueAt'] is DateTime) {
      final updatedDueAt = result['dueAt'] as DateTime;
      if (_initialActivity != null) {
        _initialActivity = _initialActivity!.copyWith(
          dueAt: updatedDueAt,
          eventDate: DateTime(
            updatedDueAt.year,
            updatedDueAt.month,
            updatedDueAt.day,
          ),
        );
      }
    }

    if (result == true || result is Map<String, dynamic>) {
      await _loadActivity();
      _activityService.refresh();

      try {
        final calendarController = Get.find<CalendarController>();
        await calendarController.loadActivities();
      } catch (e) {
        //
      }

      try {
        await InteractiveCalendarController.to.loadCalendarData();
      } catch (e) {
        //
      }

      try {
        if (Get.isRegistered<SelectedDayController>()) {
          await Get.find<SelectedDayController>().loadActivities();
        }
      } catch (e) {
        //
      }

      try {
        final homeController = Get.find<UserHomeController>();
        homeController.refreshData();
      } catch (e) {
        //
      }
    }
  }
}
