import 'package:pablife/shared/themes/app_palette.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../dashboard/widgets/goal_progress_card.dart';
import '../controllers/user_home_controller.dart';

class UserHomeGoalsProgressSection extends StatefulWidget {
  const UserHomeGoalsProgressSection({super.key});

  @override
  State<UserHomeGoalsProgressSection> createState() =>
      _UserHomeGoalsProgressSectionState();
}

class _UserHomeGoalsProgressSectionState
    extends State<UserHomeGoalsProgressSection> {
  final ActivityRepository _repository = ActivityRepository();
  final AuthService _authService = AuthService.instance;

  List<ActivityModel> _allGoals = [];

  /// Dias marcados de cada meta (meta diária).
  Map<String, int> _checkedDays = {};
  bool _isLoading = true;
  bool _isExpanded = false;

  /// Recarrega junto com o Dashboard (por exemplo, depois de marcar a meta
  /// na agenda). O atraso junta várias atualizações seguidas numa só busca.
  UserHomeController? _home;
  Timer? _reloadDebounce;

  final List<Color> _goalColors = [
    const AppColor(0xFFA8D5A3),
    const AppColor(0xFFE8D99F),
    const AppColor(0xFFFFB3BA),
    const AppColor(0xFFBAE1FF),
    const AppColor(0xFFDCC9FF),
    const AppColor(0xFFFFDBAC),
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    if (Get.isRegistered<UserHomeController>()) {
      _home = Get.find<UserHomeController>()..addListener(_onHomeUpdated);
    }
  }

  @override
  void dispose() {
    _home?.removeListener(_onHomeUpdated);
    _reloadDebounce?.cancel();
    super.dispose();
  }

  void _onHomeUpdated() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _loadGoals(silent: true);
    });
  }

  Future<void> _loadGoals({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final response = await _repository.getAllGoals(userId: userId);
      if (response.success && response.data != null) {
        final goals = response.data!;
        final checked = await _repository.getCheckedDaysCount(
          goals.map((g) => g.id).toList(),
        );
        if (!mounted) return;
        setState(() {
          _checkedDays = checked.success ? checked.data ?? {} : {};
          _allGoals = goals;

          // Metas com todos os dias cumpridos vão para o fim.
          _allGoals.sort((a, b) {
            final aDone = _calculateProgress(a)['isComplete'] as bool;
            final bDone = _calculateProgress(b)['isComplete'] as bool;
            if (aDone != bDone) return aDone ? 1 : -1;

            return b.createdAt.compareTo(a.createdAt);
          });
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getColorForIndex(int index) {
    return _goalColors[index % _goalColors.length];
  }

  /// Meta diária: progresso = dias marcados ÷ dias da meta (da criação ao
  /// prazo, contando os dois; sem prazo, só o dia da criação), como no
  /// planner e no card de metas do Dashboard.
  Map<String, dynamic> _calculateProgress(ActivityModel goal) {
    DateTime dateOnly(DateTime d) {
      final local = d.toLocal();
      return DateTime(local.year, local.month, local.day);
    }

    final start = dateOnly(goal.createdAt);
    final end = goal.dueAt == null ? start : dateOnly(goal.dueAt!);
    final totalDays = (end.difference(start).inDays + 1).clamp(1, 100000);
    final daysCompleted = (_checkedDays[goal.id] ?? 0).clamp(0, totalDays);
    final isComplete = daysCompleted >= totalDays;
    final isExpired = !isComplete && dateOnly(DateTime.now()).isAfter(end);

    return {
      'daysCompleted': daysCompleted,
      'totalDays': totalDays,
      'percentage': ((daysCompleted / totalDays) * 100).round().clamp(0, 100),
      'isExpired': isExpired,
      'isComplete': isComplete,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _allGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColor(0xFF1A1A1A),
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 16),

          ...(_isExpanded ? _allGoals : _allGoals.take(3))
              .toList()
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final goal = entry.value;
                final color = _getColorForIndex(index);
                final progressData = _calculateProgress(goal);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GoalProgressCard(
                    goalName: goal.name,
                    daysCompleted: progressData['daysCompleted'],
                    totalDays: progressData['totalDays'],
                    percentage: progressData['percentage'],
                    color: color,
                    isCompleted: progressData['isComplete'],
                    progressLabel: 'Dias cumpridos',
                    isExpired: progressData['isExpired'],
                    onTap: () async {
                      final result = await Get.toNamed(
                        '/calendar/activity-details',
                        arguments: goal,
                      );

                      if (result == true || result is Map<String, dynamic>) {
                        _loadGoals();
                      }
                    },
                  ),
                );
              }),

          if (_allGoals.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'Ver menos' : 'Ver mais',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor(0xFF0C8DA1),
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
