import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pablife/modules/dashboard/dashboard_controller.dart';
import '../controllers/user_home_controller.dart';
import 'user_home_task_button_widget.dart';
import 'section_empty_state_widget.dart';
import '../../../infra/services/auth_service.dart';
import '../../../widgets/dialogs/premium_lock_dialog.dart';

class UserHomeTasksSectionWidget extends StatelessWidget {
  final UserHomeController controller;

  const UserHomeTasksSectionWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final todayTasks = controller.todayTasks;

    if (todayTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SectionEmptyState(
          icon: LucideIcons.clipboardCheck,
          title: 'Nenhuma tarefa para hoje',
          description: 'Crie uma tarefa e ela será mostrada aqui.',
          buttonLabel: 'Criar tarefa',
          onAction: _handleCreateTask,
          backgroundColor: const Color(0xFFF5F3FF),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarefas de hoje',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Instrument Sans',
            ),
          ),
          const SizedBox(height: 16),
          if (todayTasks.isNotEmpty)
            ...todayTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: UserHomeTaskButtonWidget(
                  task: task,
                  onTap: () {
                    DashboardController.to.changeTab(1);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCreateTask() async {
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

    final result = await Get.toNamed('/calendar/task-editor');
    if (result == true || result is Map<String, dynamic>) {
      await controller.loadActivities();
    }
  }
}
