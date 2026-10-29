import 'dart:convert';

class WeeklyTaskSummary {
  final double percentage;

  WeeklyTaskSummary({required this.percentage});

  factory WeeklyTaskSummary.fromMap(Map<String, dynamic> map) {
    return WeeklyTaskSummary(
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'percentage': percentage};
  }
}

class WeeklyGoalSummary {
  final String goalId;
  final String name;
  final String? description;
  final DateTime? dueAt;
  final double percentage;

  WeeklyGoalSummary({
    required this.goalId,
    required this.name,
    this.description,
    this.dueAt,
    required this.percentage,
  });

  factory WeeklyGoalSummary.fromMap(Map<String, dynamic> map) {
    return WeeklyGoalSummary(
      goalId: map['goal_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      dueAt: map['due_at'] != null ? DateTime.parse(map['due_at']) : null,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'name': name,
      'description': description,
      'due_at': dueAt?.toIso8601String(),
      'percentage': percentage,
    };
  }
}

class WeeklyTaskActivitySummaryModel {
  final String userId;
  final DateTime weekStartDate;
  final List<List<int>> weekDayCounts;
  final List<WeeklyTaskSummary> tasks;
  final List<WeeklyGoalSummary> goals;

  WeeklyTaskActivitySummaryModel({
    required this.userId,
    required this.weekStartDate,
    required this.weekDayCounts,
    required this.tasks,
    required this.goals,
  });

  double get tasksPercentage {
    if (tasks.isEmpty) return 0.0;
    return tasks.first.percentage;
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'week_day_counts': weekDayCounts,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'goals': goals.map((g) => g.toMap()).toList(),
    };
  }

  factory WeeklyTaskActivitySummaryModel.fromMap(Map<String, dynamic> map) {
    List<List<int>> parsedCounts = [];
    if (map['week_day_counts'] != null) {
      final counts = map['week_day_counts'] as List;
      parsedCounts = counts.map((day) {
        if (day is List) {
          return day.map((e) => (e as num).toInt()).toList();
        }
        return <int>[0, 0];
      }).toList();
    }

    List<WeeklyTaskSummary> parsedTasks = [];
    if (map['tasks'] != null) {
      final tasksData = map['tasks'] as List;
      parsedTasks = tasksData
          .map((t) => WeeklyTaskSummary.fromMap(t as Map<String, dynamic>))
          .toList();
    }

    List<WeeklyGoalSummary> parsedGoals = [];
    if (map['goals'] != null) {
      final goalsData = map['goals'] as List;
      parsedGoals = goalsData
          .map((g) => WeeklyGoalSummary.fromMap(g as Map<String, dynamic>))
          .toList();
    }

    return WeeklyTaskActivitySummaryModel(
      userId: map['user_id'] as String,
      weekStartDate: DateTime.parse(map['week_start_date'] as String),
      weekDayCounts: parsedCounts,
      tasks: parsedTasks,
      goals: parsedGoals,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeeklyTaskActivitySummaryModel.fromJson(String source) =>
      WeeklyTaskActivitySummaryModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
