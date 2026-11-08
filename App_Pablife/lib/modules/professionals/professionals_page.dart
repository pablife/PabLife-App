import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/next_slot_label.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/pab_page_title.dart';
import '../home/pages/user_home_page.dart';
import 'professionals_controller.dart';
import 'widgets/clock_filter_button_widget.dart';
import 'widgets/professional_profile_sections.dart';
import 'widgets/professionals_list_widget.dart';

class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  static const route = '/professionals';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalsController>(
      builder: (controller) {
        final wide = isWideLayout(context);

        return Scaffold(
          backgroundColor: PabColors.background,
          body: wide
              // Computador: lista à esquerda e o perfil aberto ao lado.
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 440,
                      child: _ListColumn(controller: controller, wide: true),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _ProfilePanel(controller: controller),
                      ),
                    ),
                  ],
                )
              : _ListColumn(controller: controller, wide: false),
        );
      },
    );
  }
}

class _ListColumn extends StatelessWidget {
  final ProfessionalsController controller;
  final bool wide;

  const _ListColumn({required this.controller, required this.wide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(controller: controller),
        Expanded(
          child: ProfessionalsListWidget(
            isLoading: controller.isLoading,
            professionals: controller.filteredProfessionals,
            showOnlyScheduled: controller.showOnlyScheduled,
            // No computador o clique abre o perfil no painel ao lado.
            onProfessionalTap: wide
                ? controller.selectProfessional
                : controller.openProfessional,
            onCalendarTap: controller.handleCalendarAction,
            selected: wide ? controller.selected : null,
            topicsOf: controller.topicsOf,
            nextSlotOf: controller.nextSlotOf,
          ),
        ),
      ],
    );
  }
}

/// Topo escuro: título, notificações, busca e Psicólogos/Nutricionistas.
class _Header extends StatelessWidget {
  final ProfessionalsController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheduledCount = controller.filteredProfessionals
        .where((p) => p.hasAppointment)
        .length;

    return Container(
      decoration: const BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(child: PabPageTitle('Profissionais')),
                  PabNotificationBell(),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.only(left: 14),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: PabColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 15,
                          color: PabColors.ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar profissional',
                          hintStyle: TextStyle(color: PabColors.muted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: controller.showOnlyScheduled
                          ? 'Mostrar todos'
                          : 'Só com consulta marcada',
                      child: ClockFilterButtonWidget(
                        showOnlyScheduled: controller.showOnlyScheduled,
                        scheduledCount: scheduledCount,
                        onTap: controller.toggleScheduledFilter,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PabColors.onInk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final type in controller.professionalTypes)
                      Expanded(
                        child: _TypeTab(
                          label: type,
                          selected: controller.selectedType == type,
                          onTap: () => controller.changeType(type),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.availableTopics.isNotEmpty) ...[
                const SizedBox(height: 14),
                _TopicChips(controller: controller),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtro por tema: Todos, Ansiedade, Autoestima…
class _TopicChips extends StatelessWidget {
  final ProfessionalsController controller;

  const _TopicChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topics = <String?>[null, ...controller.availableTopics];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final topic = topics[index];
          final on = controller.selectedTopic == topic;
          return Semantics(
            button: true,
            selected: on,
            child: Material(
              color: on ? PabColors.accent : PabColors.card,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => controller.selectTopic(topic),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Text(
                      topic ?? 'Todos',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? PabColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? PabColors.ink : PabColors.onInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Perfil do profissional selecionado, ao lado da lista (só no computador).
class _ProfilePanel extends StatelessWidget {
  final ProfessionalsController controller;

  const _ProfilePanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final professional = controller.selected;

    return Container(
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: professional == null
          ? Center(
              child: Text(
                controller.isLoading ? '' : 'Escolha um profissional na lista',
                style: const TextStyle(fontSize: 16, color: PabColors.muted),
              ),
            )
          : SingleChildScrollView(
              key: ValueKey(professional.professional.id),
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfessionalAvatar(
                            imageUrl: professional.user.imageUrl,
                            size: 132,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  professional.user.fullName,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: PabColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ProfessionalTypeChip(
                                      professional.typeFormatted,
                                    ),
                                    for (final topic
                                        in controller
                                            .topicsOf(professional)
                                            .take(3))
                                      ProfessionalTypeChip(topic, soft: true),
                                  ],
                                ),
                                if (controller.nextSlotOf(professional)
                                    case final next?) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Próximo horário: ${nextSlotLabel(next)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: PabColors.accentText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ProfessionalProfileBody(
                        professional: professional,
                        onWhatsApp: () =>
                            controller.openWhatsAppIfAllowed(professional),
                        onScheduleAction: () =>
                            controller.handleCalendarAction(professional),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
