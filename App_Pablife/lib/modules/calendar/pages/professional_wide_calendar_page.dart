import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/professional_wide_calendar_controller.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../professional_area/week_pattern_sheet.dart';
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
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: WideAgendaColors.border),
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
    final c = controller;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Atendimentos online de 50 min. Os pacientes só veem o que '
            'estiver livre.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: PabColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${c.freeCount} ${c.freeCount == 1 ? 'horário livre' : 'horários livres'} no período',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PabColors.accentText,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => c.createSlot(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar horário'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: PabColors.accent,
              foregroundColor: PabColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Semana padrão',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const Text(
                  'repete toda semana',
                  style: TextStyle(fontSize: 12, color: PabColors.muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final id = c.professionalId;
                    if (id == null) return;
                    final changed = await WeekPatternSheet.open(
                      context,
                      professionalId: id,
                      service: c.agenda,
                    );
                    if (changed) await c.load();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: PabColors.ink,
                    side: const BorderSide(color: PabColors.lineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text(
                    'Editar semana padrão',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: WideMiniMonth(
              key: ValueKey('${c.focusDate.year}-${c.focusDate.month}'),
              initialMonth: c.focusDate,
              selectedDay: c.focusDate,
              onDayTap: c.openDay,
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legenda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _legend(
                  PabColors.soft,
                  PabColors.accentText,
                  'Livre · toque para bloquear',
                ),
                _legend(
                  PabColors.lilac,
                  PabColors.lilacText,
                  'Criado por você (avulso)',
                ),
                _legend(PabColors.ink, PabColors.ink, 'Consulta marcada'),
                _legend(
                  PabColors.track,
                  const Color(0xFFB5C0C1),
                  'Bloqueado · toque para liberar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color fill, Color border, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 1.4),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: PabColors.ink),
          ),
        ),
      ],
    ),
  );

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
