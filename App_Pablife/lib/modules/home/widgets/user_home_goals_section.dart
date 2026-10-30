import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_home_controller.dart';
import 'user_home_goal_card_widget.dart';
import 'section_empty_state_widget.dart';
import '../../../infra/services/auth_service.dart';
import '../../../widgets/dialogs/premium_lock_dialog.dart';

class UserHomeGoalsSection extends StatelessWidget {
  final UserHomeController controller;

  const UserHomeGoalsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final goalCards = controller.goalCards;

    if (goalCards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SectionEmptyState(
          icon: Icons.track_changes,
          title: 'Nenhuma meta criada',
          description:
              'Crie metas para acompanhar seu progresso e alcançar seus objetivos.',
          buttonLabel: 'Criar meta',
          onAction: _handleCreateGoal,
          backgroundColor: const Color(0xFFFFF5F5),
        ),
      );
    }

    return UserHomeGoalCardWidget(goalCards: goalCards);
  }

  Future<void> _handleCreateGoal() async {
    final authService = AuthService.instance;

    await authService.reloadUserAccessInfo();
    if (!authService.canAccessPlanner) {
      Get.dialog(
        const PremiumLockDialog(
          message:
              'Você precisa de uma assinatura ativa ou período de trial para usar o Planner. '
              'Assine um plano para ter acesso!',
          contentType: 'Planner',
          contentTitle: 'Meu Planner',
        ),
      );
      return;
    }

    final result = await Get.toNamed('/calendar/goal-editor');
    if (result == true || result is Map<String, dynamic>) {
      await controller.loadActivities();
    }
  }
}
