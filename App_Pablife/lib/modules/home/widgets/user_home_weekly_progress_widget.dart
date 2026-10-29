import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/user_home_controller.dart';
import 'weekly_progress_chart.dart';

class UserHomeWeeklyProgressWidget extends StatelessWidget {
  final UserHomeController controller;

  const UserHomeWeeklyProgressWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.hasWeeklyProgress) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextDefault(
            'Progresso Semanal',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.aquaText,
          ),
          const SizedBox(height: 24),
          WeeklyProgressChart(weeklyData: controller.weeklyProgress),
        ],
      ),
    );
  }
}
