import 'package:flutter/material.dart';

import '../../../shared/themes/pab_colors.dart';
import '../dashboard_controller.dart';

/// Abas na ordem da barra (e do menu lateral): Profissionais (Pacientes para
/// o profissional), Dashboard, Agenda, Mentorias e Perfil. O índice é o da
/// lista de telas do DashboardPage.
List<({int index, IconData icon, String label})> dashboardTabs({
  required bool isProfessional,
}) => [
  (
    index: 3,
    icon: Icons.work_outline,
    label: isProfessional ? 'Pacientes' : 'Profissionais',
  ),
  (index: 0, icon: Icons.home_outlined, label: 'Dashboard'),
  (index: 1, icon: Icons.calendar_today_outlined, label: 'Agenda'),
  (index: 2, icon: Icons.menu_book_outlined, label: 'Mentorias'),
  (index: 4, icon: Icons.person_outline, label: 'Perfil'),
];

/// Barra inferior do celular: fundo escuro, ícone com nome e o item ativo
/// numa cápsula.
class DashboardNavbar extends StatelessWidget {
  final DashboardController controller;
  final bool isProfessional;

  const DashboardNavbar({
    super.key,
    required this.controller,
    this.isProfessional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.ink,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            children: [
              for (final tab in dashboardTabs(isProfessional: isProfessional))
                Expanded(
                  child: DashboardNavbarItem(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: controller.currentIndex == tab.index,
                    onTap: () => controller.changeTab(tab.index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardNavbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DashboardNavbarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? PabColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? PabColors.ink : PabColors.navIdle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? Colors.white : PabColors.navIdle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
