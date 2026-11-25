import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/themes/pab_colors.dart';

/// Abas na ordem da barra (e do menu lateral): Profissionais (Pacientes para
/// o profissional), Dashboard, Agenda, Mentorias e Perfil. O índice é o da
/// lista de telas do DashboardPage.
List<({int index, IconData icon, String label})> dashboardTabs({
  required bool isProfessional,
}) => isProfessional
    // Profissional (canvas PD): Dashboard, Agenda, Pacientes, Histórico e
    // Perfil. O índice 2 mostra o Histórico no lugar das Mentorias.
    ? [
        (index: 0, icon: Icons.home_outlined, label: 'Dashboard'),
        (index: 1, icon: Icons.calendar_today_outlined, label: 'Agenda'),
        (index: 3, icon: Icons.groups_outlined, label: 'Pacientes'),
        (index: 2, icon: Icons.history_rounded, label: 'Histórico'),
        (index: 4, icon: Icons.person_outline, label: 'Perfil'),
      ]
    : [
        (index: 3, icon: Icons.work_outline, label: 'Profissionais'),
        (index: 0, icon: Icons.home_outlined, label: 'Dashboard'),
        (index: 1, icon: Icons.calendar_today_outlined, label: 'Agenda'),
        (index: 2, icon: Icons.menu_book_outlined, label: 'Mentorias'),
        (index: 4, icon: Icons.person_outline, label: 'Perfil'),
      ];

/// Espaço que a barra flutuante ocupa no fim da tela (celular). Cada aba soma
/// isso ao fim da rolagem, para o último item não ficar atrás da barra. Sem
/// barra flutuante (computador), é zero.
class FloatingNavSpace extends InheritedWidget {
  final double height;

  const FloatingNavSpace({
    super.key,
    required this.height,
    required super.child,
  });

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FloatingNavSpace>()?.height ??
      0;

  @override
  bool updateShouldNotify(FloatingNavSpace oldWidget) =>
      height != oldWidget.height;
}

/// Tela do celular com a barra flutuante: o conteúdo passa por trás dela.
class FloatingNavScaffold extends StatelessWidget {
  final Widget body;
  final Widget navbar;

  const FloatingNavScaffold({
    super.key,
    required this.body,
    required this.navbar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Builder(
        // Com extendBody, a altura da barra chega no espaçamento de baixo. Ele
        // é retirado daqui para não mexer nas listas e áreas seguras de dentro
        // das abas; quem precisa lê FloatingNavSpace.
        builder: (context) => FloatingNavSpace(
          height: MediaQuery.paddingOf(context).bottom,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: navbar,
    );
  }
}

/// Barra flutuante do celular: branca, solta das bordas, só com os ícones. O
/// item ativo fica numa cápsula; o nome aparece ao segurar o ícone e é lido
/// pelos leitores de tela.
class DashboardNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTab;
  final bool isProfessional;

  const DashboardNavbar({
    super.key,
    required this.currentIndex,
    required this.onTab,
    this.isProfessional = false,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(14, safe + 8)),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PabColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: PabColors.line),
              boxShadow: [
                BoxShadow(
                  color: PabColors.ink.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    for (final tab in dashboardTabs(
                      isProfessional: isProfessional,
                    ))
                      Expanded(
                        child: DashboardNavbarItem(
                          icon: tab.icon,
                          label: tab.label,
                          isSelected: currentIndex == tab.index,
                          onTap: () => onTab(tab.index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 52,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? PabColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? PabColors.ink : PabColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
