import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';

class DashboardGoalsController extends GetxController with LoaderManagerMixin {
  final ActivityRepository _repository = ActivityRepository();
  final AuthService _authService = AuthService.instance;

  List<ActivityModel> _allGoals = [];

  List<ActivityModel> get allGoals => _allGoals;

  final List<Color> _goalColors = [
    const Color(0xFFA8D5A3),
    const Color(0xFFE8D99F),
    const Color(0xFFFFB3BA),
    const Color(0xFFBAE1FF),
    const Color(0xFFDCC9FF),
    const Color(0xFFFFDBAC),
  ];

  @override
  void onInit() {
    super.onInit();
    loadGoals();
  }

  Future<void> loadGoals() async {
    changeLoading(true);
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final response = await _repository.getAllGoals(userId: userId);
      if (response.success && response.data != null) {
        _allGoals = response.data!;

        _allGoals.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        });
        update();
      }
    } finally {
      changeLoading(false);
    }
  }

  Color getColorForIndex(int index) {
    return _goalColors[index % _goalColors.length];
  }

  Map<String, dynamic> calculateProgress(ActivityModel goal) {
    if (goal.dueAt == null) {
      return {
        'daysCompleted': 0,
        'totalDays': 0,
        'percentage': 0,
        'isExpired': false,
      };
    }

    final now = DateTime.now();
    final startDate = goal.createdAt;
    final endDate = goal.dueAt!;

    final isExpired = !goal.isCompleted && now.isAfter(endDate);

    final totalDays = endDate.difference(startDate).inDays;

    final daysPassed = now.difference(startDate).inDays;

    int daysCompleted;
    if (goal.isCompleted && goal.completedAt != null) {
      daysCompleted = goal.completedAt!.difference(startDate).inDays;
    } else {
      daysCompleted = daysPassed.clamp(0, totalDays);
    }

    final percentage = totalDays > 0
        ? ((daysCompleted / totalDays) * 100).round()
        : 0;

    return {
      'daysCompleted': daysCompleted,
      'totalDays': totalDays,
      'percentage': percentage.clamp(0, 100),
      'isExpired': isExpired,
    };
  }

  Future<void> refreshGoals() async {
    await loadGoals();
  }
}
