import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../dashboard/widgets/goal_progress_card.dart';

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
  bool _isLoading = true;
  bool _isExpanded = false;

  final List<Color> _goalColors = [
    const Color(0xFFA8D5A3),
    const Color(0xFFE8D99F),
    const Color(0xFFFFB3BA),
    const Color(0xFFBAE1FF),
    const Color(0xFFDCC9FF),
    const Color(0xFFFFDBAC),
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final response = await _repository.getAllGoals(userId: userId);
      if (response.success && response.data != null) {
        setState(() {
          _allGoals = response.data!;

          _allGoals.sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }

            return b.createdAt.compareTo(a.createdAt);
          });
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getColorForIndex(int index) {
    return _goalColors[index % _goalColors.length];
  }

  Map<String, dynamic> _calculateProgress(ActivityModel goal) {
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

    int percentage;
    if (goal.isCompleted) {
      percentage = 100;
    } else {
      percentage = totalDays > 0
          ? ((daysCompleted / totalDays) * 100).round()
          : 0;
    }

    return {
      'daysCompleted': daysCompleted,
      'totalDays': totalDays,
      'percentage': percentage.clamp(0, 100),
      'isExpired': isExpired,
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
              color: Color(0xFF1A1A1A),
              fontFamily: 'Instrument Sans',
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
                    isCompleted: goal.isCompleted,
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
                    color: Color(0xFF0C8DA1),
                    fontFamily: 'Instrument Sans',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
