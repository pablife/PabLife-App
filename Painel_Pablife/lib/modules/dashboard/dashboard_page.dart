import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/themes/app_colors.dart';
import 'widgets/stat_card_widget.dart';
import 'widgets/plans_card_widget.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/states/app_widget_loading.dart';
import '../../shared/controllers/layout_controller.dart';

import 'dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const route = '/dashboard';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Dashboard');

    return GetBuilder<DashboardController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Center(child: AppWidgetLoading());
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: controller.refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const TextDefault(
                    text: 'Visão Geral',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 24),

                  // Cards de Estatísticas
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      final cardWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 48) / 3;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          StatCardWidget(
                            title: 'Usuários',
                            value: controller.totalUsers.toString(),
                            icon: Icons.people_outline,
                            color: AppColors.info,
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Profissionais',
                            value: controller.totalProfessionals.toString(),
                            icon: Icons.business_center_outlined,
                            color: AppColors.success,
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Agendamentos',
                            value: controller.totalAppointments.toString(),
                            icon: Icons.calendar_today_outlined,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.error
                                : AppColors.primaryGreen,
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Aprovações Pendentes',
                            value: controller.pendingApprovals.toString(),
                            icon: Icons.pending_actions_outlined,
                            color: controller.pendingApprovals > 0
                                ? AppColors.warning
                                : AppColors.success,
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Mentorias',
                            value: controller.totalMentorship.toString(),
                            icon: Icons.school_outlined,
                            color: const Color(0xFF9C27B0),
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Agendados',
                            value:
                                (controller.appointmentStats['scheduled'] ?? 0)
                                    .toString(),
                            icon: Icons.schedule_outlined,
                            color: const Color(0xFF2196F3),
                            width: cardWidth,
                            context: context,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Seção de Assinaturas
                  const TextDefault(
                    text: 'Assinaturas',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      final cardWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 32) / 2;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          PlansCardWidget(
                            width: cardWidth,
                            controller: controller,
                          ),

                          InkWell(
                            onTap: () =>
                                Get.toNamed('/subscriptions/cancelled'),
                            borderRadius: BorderRadius.circular(12),
                            child: StatCardWidget(
                              title: 'Assinaturas Canceladas',
                              value: controller.cancelledSubscriptions
                                  .toString(),
                              icon: Icons.cancel_outlined,
                              color: AppColors.error,
                              width: cardWidth,
                              context: context,
                            ),
                          ),
                          // Card de planos de assinatura
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Seção de Profissionais
                  const TextDefault(
                    text: 'Profissionais por Tipo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      final cardWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 32) / 2;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          StatCardWidget(
                            title: 'Nutricionistas',
                            value:
                                (controller.professionalsByType['nutritionist'] ??
                                        0)
                                    .toString(),
                            icon: Icons.restaurant_menu_outlined,
                            color: const Color(0xFF4CAF50),
                            width: cardWidth,
                            context: context,
                          ),
                          StatCardWidget(
                            title: 'Psicólogos',
                            value:
                                (controller.professionalsByType['psychologist'] ??
                                        0)
                                    .toString(),
                            icon: Icons.psychology_outlined,
                            color: const Color(0xFF2196F3),
                            width: cardWidth,
                            context: context,
                          ),
                        ],
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

  // ...existing code...
}
