import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/appointments/appointments_page.dart';
import '../../modules/banners/banners_page.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../modules/dashboard/dashboard_page.dart';
import '../../modules/finance/finance_report_page.dart';
import '../../modules/mentorship/mentorship_page.dart';
import '../../modules/notifications/notifications_page.dart';
import '../../modules/professionals/professionals_page.dart';
import '../../modules/users/users_page.dart';
import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../shared/utils/app_assets.dart';
import '../design_system/text_default.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      id: 'sidebar',
      builder: (controller) {
        // Força colapso em telas pequenas (< 1100px)
        final width = MediaQuery.of(context).size.width;
        final isSmallScreen = width < 1000;
        final isCollapsed = isSmallScreen || controller.isCollapsed;
        final theme = Theme.of(context);

        return Container(
          width: isCollapsed ? 72 : 250,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SidebarContent(
            isCollapsed: isCollapsed,
            currentRoute: controller.currentRoute,
          ),
        );
      },
    );
  }
}

class SidebarContent extends StatelessWidget {
  final bool isCollapsed;
  final String currentRoute;

  const SidebarContent({
    super.key,
    required this.isCollapsed,
    this.currentRoute = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Logo Area
        Container(
          height: 60,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isCollapsed || constraints.maxWidth < 120) {
                return Image.asset(AppAssets.appLogoPng, height: 32);
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.appLogoPng, height: 32),
                  const SizedBox(width: 12),
                  TextDefault(
                    text: 'PabLife',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurface
                        : theme.primaryColor,
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Menu Items
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: DashboardPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Usuários',
                  route: UsersPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.business_center_outlined,
                  label: 'Profissionais',
                  route: ProfessionalsPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.school_outlined,
                  label: 'Mentorias',
                  route: MentorshipPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Agendamentos',
                  route: AppointmentsPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.attach_money_outlined,
                  label: 'Financeiro',
                  route: FinanceReportPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Banners',
                  route: BannersPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
                SidebarItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notificações',
                  route: NotificationsPage.route,
                  isCollapsed: isCollapsed,
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
        ),

        // Theme Toggle
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: InkWell(
            onTap: () {
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isCollapsed || constraints.maxWidth < 60) {
                    return Center(
                      child: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: theme.iconTheme.color,
                        size: 24,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: theme.iconTheme.color,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextDefault(
                            text: isDark ? 'Modo Claro' : 'Modo Escuro',
                            fontSize: 14,
                            color:
                                theme.textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Logout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: SidebarItem(
            icon: Icons.logout,
            label: 'Sair',
            onTap: _showLogoutDialog,
            isCollapsed: isCollapsed,
            isLogout: true,
            currentRoute: currentRoute,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair do painel?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await Get.find<DashboardController>().signOut();
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final bool isCollapsed;
  final bool isLogout;
  final String currentRoute;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    required this.isCollapsed,
    this.isLogout = false,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lógica de seleção: exata ou prefixo (para sub-rotas)
    // Ex: /users seleciona /users, /users/create, /users/123
    final isSelected =
        route != null &&
        (currentRoute == route ||
            (route != '/' && currentRoute.startsWith('$route')));

    Color iconColor;
    switch (label) {
      case 'Dashboard':
        iconColor = AppColors.info;
        break;
      case 'Usuários':
        iconColor = AppColors.info;
        break;
      case 'Profissionais':
        iconColor = AppColors.success;
        break;
      case 'Mentorias':
        iconColor = const Color(0xFF9C27B0);
        break;
      case 'Agendamentos':
        iconColor = theme.brightness == Brightness.dark
            ? AppColors.error
            : AppColors.primaryGreen;
        break;
      case 'Financeiro':
        iconColor = AppColors.warning;
        break;
      case 'Banners':
        iconColor = const Color(0xFF2196F3);
        break;
      case 'Sair':
        iconColor = Colors.red;
        break;
      default:
        iconColor = theme.iconTheme.color ?? AppColors.textSecondary;
    }

    return InkWell(
      onTap:
          onTap ??
          () {
            if (route != null && currentRoute != route) {
              Get.toNamed(route!);
            }
          },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withOpacity(
                  theme.brightness == Brightness.dark ? 0.25 : 0.10,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Evita overflow durante animação de expansão
            if (isCollapsed || constraints.maxWidth < 60) {
              return Center(child: Icon(icon, color: iconColor, size: 24));
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextDefault(
                      text: label,
                      fontSize: 17,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
