import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import 'professionals_controller.dart';
import 'widgets/professional_profile_sections.dart';
import 'widgets/professionals_search_field.dart';
import 'widgets/professional_tabs_widget.dart';
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
          backgroundColor: const AppColor(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: wide
              // Computador: lista à esquerda e o perfil aberto ao lado.
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 440,
                        child: _buildListColumn(controller, wide: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _ProfilePanel(controller: controller)),
                    ],
                  ),
                )
              : _buildListColumn(controller, wide: false),
        );
      },
    );
  }

  Widget _buildListColumn(
    ProfessionalsController controller, {
    required bool wide,
  }) {
    final radius = wide
        ? BorderRadius.circular(32)
        : const BorderRadius.only(
            topLeft: Radius.circular(39),
            topRight: Radius.circular(39),
          );

    return Column(
      children: [
        const SizedBox(height: 10),
        ProfessionalsSearchField(
          controller: controller.searchController,
          showOnlyScheduled: controller.showOnlyScheduled,
          scheduledCount: controller.filteredProfessionals
              .where((p) => p.hasAppointment)
              .length,
          onChanged: (value) {},
          onClockTap: controller.toggleScheduledFilter,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            margin: wide ? const EdgeInsets.only(left: 24) : null,
            decoration: BoxDecoration(
              color: const AppColor(0xFFC1CDFF),
              borderRadius: radius,
            ),
            child: Column(
              children: [
                const SizedBox(height: 18),
                ProfessionalTabsWidget(
                  types: controller.professionalTypes,
                  selectedType: controller.selectedType,
                  onTypeSelected: controller.changeType,
                ),
                const SizedBox(height: 10),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const AppColor(0xFFC1CDFF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: professional == null
          ? Center(
              child: Text(
                controller.isLoading ? '' : 'Escolha um profissional na lista',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColor(0xFF00343C),
                ),
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
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor(0xFF00343C),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ProfessionalTypeChip(
                                  professional.typeFormatted,
                                ),
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
