import 'package:flutter/material.dart';
import '../../controllers/professional_home_controller.dart';
import '../../widgets/weekly_progress_chart.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../shared/themes/app_colors.dart';

import '../../../../infra/models/home_view_models.dart';

class ProfessionalHomeWeeklyProgressWidget extends StatelessWidget {
  final ProfessionalHomeController controller;

  const ProfessionalHomeWeeklyProgressWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyData = controller.weeklyProgress;

    if (weeklyData.every((day) => (day['total'] as int) == 0)) {
      return const SizedBox.shrink();
    }

    final chartData = weeklyData.map((data) {
      return WeeklyProgressViewModel(
        day: data['day'] as String,
        completed: data['completed'] as int,
        total: data['total'] as int,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              TextDefault(
                'Progresso da semana',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.aquaText,
              ),
              TextDefault(
                'Semana',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.aquaText,
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeeklyProgressChart(weeklyData: chartData),
        ],
      ),
    );
  }
}
