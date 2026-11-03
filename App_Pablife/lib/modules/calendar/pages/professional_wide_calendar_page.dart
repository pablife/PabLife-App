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
                        _Header(controller: controller),
                        const SizedBox(height: 12),
                        Expanded(
                          child: switch (controller.view) {
                            WideAgendaView.week => WideWeekView(
                              controller: controller,
                            ),
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

class _Header extends StatelessWidget {
  final ProfessionalWideCalendarController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: controller.goToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: WideAgendaColors.text,
            side: const BorderSide(color: WideAgendaColors.text),
            shape: const StadiumBorder(),
          ),
          child: const Text('Hoje'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Anterior',
          onPressed: () => controller.move(-1),
          icon: const Icon(Icons.chevron_left, color: WideAgendaColors.text),
        ),
        IconButton(
          tooltip: 'Próximo',
          onPressed: () => controller.move(1),
          icon: const Icon(Icons.chevron_right, color: WideAgendaColors.text),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            controller.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: WideAgendaColors.text,
            ),
          ),
        ),
        if (controller.isLoading) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WideAgendaColors.text,
            ),
          ),
        ],
        const Spacer(),
        SegmentedButton<WideAgendaView>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: WideAgendaView.week, label: Text('Semana')),
            ButtonSegment(value: WideAgendaView.month, label: Text('Mês')),
            ButtonSegment(value: WideAgendaView.year, label: Text('Ano')),
          ],
          selected: {controller.view},
          onSelectionChanged: (s) => controller.setView(s.first),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? WideAgendaColors.panel
                  : WideAgendaColors.text,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? WideAgendaColors.text
                  : Colors.transparent,
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(color: WideAgendaColors.text),
            ),
          ),
        ),
      ],
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
                _FilterRow(
                  label: 'Consultas',
                  color: WideAgendaColors.appointment,
                  value: controller.showAppointments,
                  count: controller.appointmentCount,
                  onChanged: controller.toggleAppointments,
                ),
                _FilterRow(
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

class _FilterRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final int count;
  final ValueChanged<bool> onChanged;

  const _FilterRow({
    required this.label,
    required this.color,
    required this.value,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: color,
            side: BorderSide(color: color, width: 2),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: WideAgendaColors.text,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WideAgendaColors.text,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
