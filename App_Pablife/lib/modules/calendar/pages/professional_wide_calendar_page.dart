import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/professional_wide_calendar_controller.dart';
import '../widgets/wide_agenda_views.dart';

/// Agenda do profissional no computador: coluna com "Novo horário",
/// minicalendário e filtros; à direita, semana, mês ou ano.
class ProfessionalWideCalendarPage extends StatelessWidget {
  const ProfessionalWideCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalWideCalendarController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: WideAgendaColors.background,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 240,
                  child: _SideColumn(controller: controller),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      color: WideAgendaColors.panel,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        WideAgendaHeader(
                          title: controller.title,
                          isLoading: controller.isLoading,
                          view: controller.view,
                          onToday: controller.goToday,
                          onMove: controller.move,
                          onViewChanged: controller.setView,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: switch (controller.view) {
                            WideAgendaView.day || WideAgendaView.week =>
                              WideWeekView(controller: controller),
                            WideAgendaView.month => WideMonthView(
                              controller: controller,
                            ),
                            WideAgendaView.year => WideYearView(
                              controller: controller,
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SideColumn extends StatelessWidget {
  final ProfessionalWideCalendarController controller;

  const _SideColumn({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => controller.createSlot(),
            icon: const Icon(Icons.add),
            label: const Text('Novo horário'),
            style: FilledButton.styleFrom(
              backgroundColor: WideAgendaColors.appointment,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: WideMiniMonth(
              key: ValueKey(
                '${controller.focusDate.year}-${controller.focusDate.month}',
              ),
              initialMonth: controller.focusDate,
              selectedDay: controller.focusDate,
              onDayTap: controller.openDay,
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mostrar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WideAgendaColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                WideFilterRow(
                  label: 'Consultas',
                  color: WideAgendaColors.appointment,
                  value: controller.showAppointments,
                  count: controller.appointmentCount,
                  onChanged: controller.toggleAppointments,
                ),
                WideFilterRow(
                  label: 'Horários livres',
                  color: WideAgendaColors.free,
                  value: controller.showFree,
                  count: controller.freeCount,
                  onChanged: controller.toggleFree,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: const Text(
              'Clique num espaço vazio da semana para liberar um horário. '
              'Clique num horário livre para removê-lo e numa consulta para '
              'ver os detalhes.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: WideAgendaColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WideAgendaColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
