import 'package:flutter/material.dart';

class GoalViewModel {
  final String title;
  final String description;
  final String duration;
  final String tag;
  final double? percentage;

  GoalViewModel({
    required this.title,
    required this.description,
    required this.duration,
    required this.tag,
    this.percentage,
  });
}

class TaskViewModel {
  final String label;
  final int percentage;
  final String? id;

  TaskViewModel({required this.label, required this.percentage, this.id});
}

class WeeklyProgressViewModel {
  final String day;
  final int completed;
  final int total;

  WeeklyProgressViewModel({
    required this.day,
    required this.completed,
    required this.total,
  });
}

class GoalProgressViewModel {
  final String label;
  final int percentage;
  final Color color;

  GoalProgressViewModel({
    required this.label,
    required this.percentage,
    required this.color,
  });
}
