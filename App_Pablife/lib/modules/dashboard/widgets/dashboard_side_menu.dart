import 'package:flutter/material.dart';

import '../../../shared/themes/pab_colors.dart';
import '../dashboard_controller.dart';
import 'dashboard_navbar.dart';

/// Menu lateral usado no lugar da barra de baixo em telas largas.
class DashboardSideMenu extends StatelessWidget {
  final DashboardController controller;
  final bool isProfessional;

  const DashboardSideMenu({
    super.key,
    required this.controller,
    required this.isProfessional,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: PabColors.ink,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 32),
            child: PabWordmark(),
          ),
          for (final tab in dashboardTabs(isProfessional: isProfessional))
            DashboardSideMenuItem(
              icon: tab.icon,
              label: tab.label,
              isSelected: controller.currentIndex == tab.index,
              onTap: () => controller.changeTab(tab.index),
            ),
        ],
      ),
    );
  }
}

/// Marca "pablife" do menu: círculo e o "life" na cor de destaque.
class PabWordmark extends StatelessWidget {
  final Color color;

  const PabWordmark({super.key, this.color = PabColors.onInk});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pablife',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PabColors.accent, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'pab'),
                TextSpan(
                  text: 'life',
                  style: TextStyle(color: PabColors.accent),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DashboardSideMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? PabColors.ink : PabColors.navIdle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? PabColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
