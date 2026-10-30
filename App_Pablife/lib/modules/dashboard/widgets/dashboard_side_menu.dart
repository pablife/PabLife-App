import 'package:flutter/material.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:pablife/widgets/app_logo.dart';
import 'package:pablife/widgets/app_text_vector.dart';

import '../dashboard_controller.dart';

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
    // Os índices seguem as abas do DashboardPage; só a ordem na tela muda.
    final items = [
      (
        index: 3,
        icon: RegularRounded.BRIEFCASE,
        label: isProfessional ? 'Pacientes' : 'Profissionais',
      ),
      (index: 0, icon: RegularRounded.HOME, label: 'Início'),
      (index: 1, icon: RegularRounded.CALENDAR, label: 'Agenda'),
      (index: 2, icon: RegularRounded.BOOK_ALT, label: 'Mentorias'),
      (index: 4, icon: RegularRounded.USER, label: 'Perfil'),
    ];

    return Container(
      width: 240,
      color: const Color(0xFF00262C),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 32),
            child: Row(
              children: [
                AppLogo(width: 40, height: 40),
                SizedBox(width: 10),
                AppTextVector(width: 100, height: 30),
              ],
            ),
          ),
          for (final item in items)
            DashboardSideMenuItem(
              icon: item.icon,
              label: item.label,
              isSelected: controller.currentIndex == item.index,
              onTap: () => controller.changeTab(item.index),
            ),
        ],
      ),
    );
  }
}

class DashboardSideMenuItem extends StatelessWidget {
  final String icon;
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
    final color = isSelected ? Colors.white : const Color(0xFFA9C9CE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? const Color(0xFF0C8DA1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                FUI(icon, color: color, height: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
