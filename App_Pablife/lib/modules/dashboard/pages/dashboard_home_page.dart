import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_goals_controller.dart';
import '../widgets/goal_progress_card.dart';

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardGoalsController>(
      init: DashboardGoalsController(),
      builder: (controller) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshGoals,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metas',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3142),
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (controller.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (controller.allGoals.isEmpty)
                    _buildEmptyState(context)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.allGoals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final goal = controller.allGoals[index];
                        final color = controller.getColorForIndex(index);
                        final progressData = controller.calculateProgress(goal);

                        return GoalProgressCard(
                          goalName: goal.name,
                          daysCompleted: progressData['daysCompleted'],
                          totalDays: progressData['totalDays'],
                          percentage: progressData['percentage'],
                          color: color,
                          isCompleted: goal.isCompleted,
                          isExpired: progressData['isExpired'],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta criada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie metas no Planner para acompanhar seu progresso aqui',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
