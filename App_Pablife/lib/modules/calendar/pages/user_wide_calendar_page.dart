import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/services/notification_service.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../../widgets/pab_page_title.dart';
import '../widgets/phone_agenda_views.dart';
import '../../women_health/women_health_controller.dart';
import '../../women_health/women_health_data.dart';
import '../../women_health/pages/mood_check_in_page.dart';
import '../../notifications/notifications_page.dart';
import '../controllers/professional_wide_calendar_controller.dart';
import '../controllers/user_wide_calendar_controller.dart';
import '../widgets/calendar_connect_dialog.dart';
import '../widgets/wide_agenda_views.dart';

/// Cores dos itens do planner (as mesmas do celular).
abstract final class _PlannerColors {
  static const task = AppColor(0xFF00C2A8);
  static const goal = Color(0xFF8D84F0);
  static const note = Color(0xFFE0A526);
  static const noteText = Color(0xFF6B4A00);
  static const appointment = PabColors.ink;
  static const holiday = Color(0xFFD63A74);
  static const women = WomenColors.mauve;
}

/// Agenda do usuário no computador: "+ Criar", minicalendário e filtros à
/// esquerda; semana, mês ou ano à direita.
class UserWideCalendarPage extends StatelessWidget {
  const UserWideCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WomenHealthController>(
      builder: (women) => GetBuilder<UserWideCalendarController>(
        builder: (controller) {
          if (!isWideLayout(context)) {
            return _PhoneCalendar(controller: controller, women: women);
          }
          return Scaffold(
            backgroundColor: WideAgendaColors.background,
            body: Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WideTitle(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 240,
                          child: _SideColumn(
                            controller: controller,
                            women: women,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _WithWomenHealth(
                            panel: Container(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                14,
                              ),
                              decoration: BoxDecoration(
                                color: WideAgendaColors.panel,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: WideAgendaColors.border,
                                ),
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
                                      WideAgendaView.day ||
                                      WideAgendaView.week => _UserWeekView(
                                        controller: controller,
                                      ),
                                      WideAgendaView.month => _UserMonthView(
                                        controller: controller,
                                      ),
                                      WideAgendaView.year => _UserYearView(
                                        controller: controller,
                                      ),
                                    },
                                  ),
                                  if (tracksCycle(women)) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'As fases do ciclo são estimativas e podem '
                                      'variar. Não substituem o acompanhamento com '
                                      'ginecologista.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: WideAgendaColors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A Saúde da Mulher não fica mais no planner (a escolha é no início e o
/// resumo do ciclo está no Dashboard): aqui só aparece a agenda. A marcação
/// do ciclo nos dias continua, para quem está no modo.
class _WithWomenHealth extends StatelessWidget {
  final Widget panel;

  const _WithWomenHealth({required this.panel});

  @override
  Widget build(BuildContext context) => panel;
}

// ------------------------------------------------------------------ celular

/// A mesma agenda no celular: cabeçalho em duas linhas, filtros numa janela
/// de baixo e botão "+" para criar. Abre no dia de hoje (visão Dia).
class _PhoneCalendar extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController women;

  const _PhoneCalendar({required this.controller, required this.women});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.applyPhoneDefaultView(),
    );

    return Scaffold(
      backgroundColor: PabColors.background,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Criar',
        backgroundColor: PabColors.accent,
        foregroundColor: PabColors.ink,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showCreateSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhoneHeader(
            controller: controller,
            onMore: () => _showFilterSheet(context),
          ),
          Expanded(
            child: _WithWomenHealth(
              panel: Container(
                color: PabColors.background,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                  children: [
                    _FilterChips(controller: controller, women: women),
                    const SizedBox(height: 12),
                    switch (controller.view) {
                      WideAgendaView.day => PhoneDayView(
                        controller: controller,
                        women: women.isActive ? women : null,
                      ),
                      WideAgendaView.week => PhoneWeekView(
                        controller: controller,
                        women: women.isActive ? women : null,
                      ),
                      WideAgendaView.month => PhoneMonthView(
                        controller: controller,
                        women: women.isActive ? women : null,
                      ),
                      WideAgendaView.year => PhoneYearView(
                        controller: controller,
                      ),
                    },
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PhoneAction(
                            label: 'Conectar calendário',
                            onTap: () => CalendarConnectDialog.show(
                              context,
                              womenTrailTitle: women.trail?.title,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhoneAction(
                            label: 'Apagar feitas',
                            danger: true,
                            onTap: () => controller.deleteDoneTasks(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    Widget option(String label, Color color, VoidCallback onTap) => ListTile(
      leading: CircleAvatar(radius: 8, backgroundColor: color),
      title: Text(label, style: const TextStyle(color: WideAgendaColors.text)),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WideAgendaColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Criar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: WideAgendaColors.text,
                ),
              ),
            ),
            option('Tarefa', _PlannerColors.task, controller.createTask),
            option('Meta', _PlannerColors.goal, controller.createGoal),
            option('Anotação', _PlannerColors.note, controller.createNote),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WideAgendaColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: GetBuilder<UserWideCalendarController>(
          builder: (c) {
            final totals = c.totals;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mostrar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: WideAgendaColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  WideFilterRow(
                    label: 'Tarefas',
                    color: _PlannerColors.task,
                    value: c.showTasks,
                    count: totals.tasks,
                    onChanged: (v) => c.setFilter(tasks: v),
                  ),
                  WideFilterRow(
                    label: 'Metas',
                    color: _PlannerColors.goal,
                    value: c.showGoals,
                    count: totals.goals,
                    onChanged: (v) => c.setFilter(goals: v),
                  ),
                  WideFilterRow(
                    label: 'Anotações',
                    color: _PlannerColors.note,
                    value: c.showNotes,
                    count: totals.notes,
                    onChanged: (v) => c.setFilter(notes: v),
                  ),
                  WideFilterRow(
                    label: 'Consultas',
                    color: _PlannerColors.appointment,
                    value: c.showAppointments,
                    count: totals.appointments,
                    onChanged: (v) => c.setFilter(appointments: v),
                  ),
                  WideFilterRow(
                    label: 'Feriados',
                    color: _PlannerColors.holiday,
                    value: c.showHolidays,
                    count: c.holidaysInRange,
                    onChanged: c.setShowHolidays,
                  ),
                  for (final f in _womenFilters(women, c))
                    WideFilterRow(
                      label: f.label,
                      color: f.color,
                      value: f.on,
                      count: f.count,
                      onChanged: (_) => f.toggle(),
                    ),
                  const SizedBox(height: 8),
                  _ConnectCalendarButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      CalendarConnectDialog.show(
                        context,
                        womenTrailTitle: women.trail?.title,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _DeleteDoneTasksButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      c.deleteDoneTasks(context);
                    },
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

/// Botões do fim da agenda no celular.
class _PhoneAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _PhoneAction({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: PabColors.card,
        foregroundColor: danger ? const Color(0xFFA3263F) : PabColors.ink,
        side: BorderSide(
          color: danger ? const Color(0xFFF2C4CF) : PabColors.lineStrong,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Topo da agenda no celular (canvas "Agenda — mobile"): título, período,
/// Hoje, anterior e próximo, e as visões Dia, Semana, Mês e Ano.
class _PhoneHeader extends StatelessWidget {
  final UserWideCalendarController controller;
  final VoidCallback onMore;

  const _PhoneHeader({required this.controller, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    Widget square(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
      message: tooltip,
      child: Material(
        color: PabColors.onInk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: PabColors.onInk),
          ),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PabPageTitle('Agenda'),
                        const SizedBox(height: 2),
                        Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PabColors.onInk,
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: c.goToday,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: PabColors.onInk,
                      side: BorderSide(
                        color: PabColors.onInk.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hoje',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  square(Icons.chevron_left, 'Anterior', () => c.move(-1)),
                  const SizedBox(width: 6),
                  square(Icons.chevron_right, 'Próximo', () => c.move(1)),
                  const SizedBox(width: 6),
                  square(Icons.more_horiz, 'Mais opções', onMore),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PabColors.onInk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final (view, label) in const [
                      (WideAgendaView.day, 'Dia'),
                      (WideAgendaView.week, 'Semana'),
                      (WideAgendaView.month, 'Mês'),
                      (WideAgendaView.year, 'Ano'),
                    ])
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: c.view == view,
                          child: Material(
                            color: c.view == view
                                ? PabColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              onTap: () => c.setView(view),
                              borderRadius: BorderRadius.circular(11),
                              child: SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.view == view
                                          ? PabColors.ink
                                          : PabColors.onInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O que aparece na agenda, em pílulas que ligam e desligam.
class _FilterChips extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController women;

  const _FilterChips({required this.controller, required this.women});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final chips = [
      (
        'Tarefas',
        _PlannerColors.task,
        c.showTasks,
        () => c.setFilter(tasks: !c.showTasks),
      ),
      (
        'Metas',
        _PlannerColors.goal,
        c.showGoals,
        () => c.setFilter(goals: !c.showGoals),
      ),
      (
        'Anotações',
        _PlannerColors.note,
        c.showNotes,
        () => c.setFilter(notes: !c.showNotes),
      ),
      (
        'Consultas',
        _PlannerColors.appointment,
        c.showAppointments,
        () => c.setFilter(appointments: !c.showAppointments),
      ),
      (
        'Feriados',
        _PlannerColors.holiday,
        c.showHolidays,
        () => c.setShowHolidays(!c.showHolidays),
      ),
      for (final f in _womenFilters(women, c))
        (f.label, f.color, f.on, f.toggle),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final (label, color, on, toggle) = chips[index];
          return Semantics(
            button: true,
            toggled: on,
            child: Material(
              color: on ? PabColors.card : Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: on ? PabColors.lineStrong : PabColors.line,
                ),
              ),
              child: InkWell(
                onTap: toggle,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? color : PabColors.track,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: on ? PabColors.ink : PabColors.muted,
                          decoration: on ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
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

/// Filtros da Saúde da Mulher na agenda: quem acompanha o ciclo vê
/// Menstruação, Fértil e Ovulação separados; as outras trilhas, um filtro só.
List<({String label, Color color, bool on, int count, VoidCallback toggle})>
_womenFilters(WomenHealthController women, UserWideCalendarController c) {
  if (!women.isActive) return const [];
  void refresh() => c.update();
  if (!tracksCycle(women)) {
    return [
      (
        label: women.trail!.title,
        color: _PlannerColors.women,
        on: women.showBand,
        count: c.weekDays.length,
        toggle: () {
          women.setShowBand(!women.showBand);
          refresh();
        },
      ),
    ];
  }
  int days(bool Function(WomenCyclePhase p) test) => c.weekDays.where((d) {
    final phase = women.cyclePhaseOn(d);
    return phase != null && test(phase);
  }).length;
  return [
    (
      label: 'Menstruação',
      color: PabColors.menstruation,
      on: women.showMenstruation,
      count: days((p) => p.kind == WomenCycleKind.menstruation),
      toggle: () {
        women.setCycleFilter(menstruation: !women.showMenstruation);
        refresh();
      },
    ),
    (
      label: 'Fértil',
      color: PabColors.fertile,
      on: women.showFertile,
      count: days((p) => p.kind == WomenCycleKind.fertile && !p.isOvulation),
      toggle: () {
        women.setCycleFilter(fertile: !women.showFertile);
        refresh();
      },
    ),
    (
      label: 'Ovulação',
      color: CycleColors.ovulationDot,
      on: women.showOvulation,
      count: days((p) => p.isOvulation),
      toggle: () {
        women.setCycleFilter(ovulation: !women.showOvulation);
        refresh();
      },
    ),
  ];
}

// ------------------------------------------------------------ coluna lateral

class _SideColumn extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController women;

  const _SideColumn({required this.controller, required this.women});

  @override
  Widget build(BuildContext context) {
    final totals = controller.totals;
    final cycle = tracksCycle(women);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Criar',
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) => switch (value) {
              'task' => controller.createTask(),
              'goal' => controller.createGoal(),
              _ => controller.createNote(),
            },
            itemBuilder: (_) => [
              _menuItem('task', 'Tarefa', _PlannerColors.task),
              _menuItem('goal', 'Meta', _PlannerColors.goal),
              _menuItem('note', 'Anotação', _PlannerColors.note),
            ],
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: WideAgendaColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: PabColors.ink, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Criar',
                    style: TextStyle(
                      color: PabColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cycle) ...[const SizedBox(height: 14), _CycleCard(women: women)],
          const SizedBox(height: 14),
          _card(
            child: WideMiniMonth(
              key: ValueKey(
                '${controller.focusDate.year}-${controller.focusDate.month}',
              ),
              initialMonth: controller.focusDate,
              selectedDay: controller.focusDate,
              onDayTap: controller.openDay,
              dayTint: cycle ? (day) => cycleTintOn(women, day) : null,
              legend: [
                if (cycle && women.showMenstruation)
                  (CycleColors.menstruationFill, 'Menstruação'),
                if (cycle && women.showFertile)
                  (CycleColors.fertileFill, 'Fértil (previsto)'),
                if (cycle && women.showOvulation)
                  (CycleColors.ovulationFill, 'Ovulação (prevista)'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mostrar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: WideAgendaColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                for (final f in _womenFilters(women, controller))
                  WideFilterRow(
                    label: f.label,
                    color: f.color,
                    value: f.on,
                    count: f.count,
                    onChanged: (_) => f.toggle(),
                  ),
                WideFilterRow(
                  label: 'Tarefas',
                  color: _PlannerColors.task,
                  value: controller.showTasks,
                  count: totals.tasks,
                  onChanged: (v) => controller.setFilter(tasks: v),
                ),
                WideFilterRow(
                  label: 'Metas',
                  color: _PlannerColors.goal,
                  value: controller.showGoals,
                  count: totals.goals,
                  onChanged: (v) => controller.setFilter(goals: v),
                ),
                WideFilterRow(
                  label: 'Anotações',
                  color: _PlannerColors.note,
                  value: controller.showNotes,
                  count: totals.notes,
                  onChanged: (v) => controller.setFilter(notes: v),
                ),
                WideFilterRow(
                  label: 'Consultas',
                  color: _PlannerColors.appointment,
                  value: controller.showAppointments,
                  count: totals.appointments,
                  onChanged: (v) => controller.setFilter(appointments: v),
                ),
                WideFilterRow(
                  label: 'Feriados',
                  color: _PlannerColors.holiday,
                  value: controller.showHolidays,
                  count: controller.holidaysInRange,
                  onChanged: controller.setShowHolidays,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConnectCalendarButton(
            onPressed: () => CalendarConnectDialog.show(
              context,
              womenTrailTitle: women.trail?.title,
            ),
          ),
          const SizedBox(height: 8),
          _DeleteDoneTasksButton(
            onPressed: () => controller.deleteDoneTasks(context),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: WideAgendaColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WideAgendaColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WideAgendaColors.border),
      ),
      child: child,
    );
  }
}

/// Título "Agenda" com o sino de notificações (computador).
class _WideTitle extends StatelessWidget {
  const _WideTitle();

  @override
  Widget build(BuildContext context) {
    final service = Get.find<NotificationService>();
    final square = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: PabColors.lineStrong),
    );
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Agenda',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
        ),
        GetBuilder<NotificationService>(
          id: 'notification_count',
          builder: (_) {
            final count = service.unreadCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Tooltip(
                  message: 'Notificações',
                  child: Material(
                    color: Colors.white,
                    shape: square,
                    child: InkWell(
                      customBorder: square,
                      onTap: () => Get.toNamed(NotificationsPage.route),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.notifications_none,
                          size: 21,
                          color: PabColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: IgnorePointer(
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: PabColors.pink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Cartão escuro do ciclo, no topo da coluna (Saúde da Mulher).
class _CycleCard extends StatelessWidget {
  final WomenHealthController women;

  const _CycleCard({required this.women});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final day = women.cycleDay(today);
    final phase = women.cyclePhaseOn(today);
    final phaseLabel = switch (phase?.kind) {
      WomenCycleKind.menstruation => 'Menstruação',
      WomenCycleKind.fertile =>
        phase!.label.contains('ovulação') ? 'Ovulação' : 'Período fértil',
      _ => phase?.label.replaceAll(' (estimativa)', '') ?? '',
    };
    final next = women.nextPeriod;
    final nextLabel =
        '${next.day} de ${ProfessionalWideCalendarController.monthNames[next.month - 1].toLowerCase()}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dia $day do ciclo',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PabColors.onInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$phaseLabel · próxima prevista em $nextLabel',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: PabColors.onInkSoft,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: MoodCheckInPage.open,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                backgroundColor: PabColors.pink,
                foregroundColor: PabColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                women.todayCheckIn == null
                    ? 'Registrar como estou hoje'
                    : 'Hoje: ${women.todayCheckIn} · ver registro',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ semana

class _UserWeekView extends StatefulWidget {
  final UserWideCalendarController controller;

  /// Celular: coluna das horas mais estreita.
  const _UserWeekView({required this.controller});

  @override
  State<_UserWeekView> createState() => _UserWeekViewState();
}

class _UserWeekViewState extends State<_UserWeekView> {
  static const _hourHeight = 60.0;

  double get _gutter => 56;

  final _scroll = ScrollController(initialScrollOffset: 7 * _hourHeight);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Metas (e itens de dia inteiro) vão na faixa "dia todo" do topo.
  static bool _isAllDay(ActivityModel a) =>
      a.type == 'goal' || a.allDay || a.dueAt == null;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final days = controller.weekDays;
    final eventsByDay = {for (final d in days) d: controller.eventsOn(d)};
    final women = WomenHealthController.to;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: _gutter),
            for (final day in days)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      wideWeekdayShort[day.weekday % 7],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: WideAgendaColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    WideDayNumber(day: day, size: 36),
                    if (women.isActive) _DayMood(mood: women.moodOn(day)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
        // Faixa "dia todo" (metas).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _gutter,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8, top: 4),
                  child: Text(
                    'dia\ntodo',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: WideAgendaColors.muted,
                    ),
                  ),
                ),
              ),
              for (final day in days)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minHeight: 28),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: WideAgendaColors.grid,
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (women.bandOn(day) case final band?)
                          _BandChip(band: band),
                        if (controller.holidayOn(day) case final holiday?)
                          _HolidayChip(name: holiday),
                        for (final item in eventsByDay[day]!.where(_isAllDay))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: SizedBox(
                              height: 24,
                              child: _PlannerChip(
                                item: item,
                                day: day,
                                controller: controller,
                                showTime: false,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: WideAgendaColors.grid),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _gutter,
                  child: Column(
                    children: [
                      for (var hour = 0; hour < 24; hour++)
                        SizedBox(
                          height: _hourHeight,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8, top: 2),
                              child: Text(
                                '${wideTwo(hour)}:00',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: WideAgendaColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final day in days)
                  Expanded(
                    child: _dayColumn(
                      day,
                      eventsByDay[day]!.where((a) => !_isAllDay(a)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(DateTime day, List<ActivityModel> items) {
    final now = DateTime.now();
    final isToday = wideSameDay(day, now);
    final column = Container(
      color: isToday ? WideAgendaColors.todayColumn : null,
      child: Column(
        children: [
          for (var hour = 0; hour < 24; hour++)
            _hourCell(day, items.where((a) => a.dueAt!.hour == hour).toList()),
        ],
      ),
    );
    if (!isToday) return column;

    // Linha rosa no horário de agora.
    final top = (now.hour + now.minute / 60) * _hourHeight;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        column,
        Positioned(
          top: top - 4,
          left: -4,
          right: 0,
          child: IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PabColors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Container(height: 2, color: PabColors.pink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hourCell(DateTime day, List<ActivityModel> items) {
    return Container(
      height: _hourHeight,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: WideAgendaColors.grid, width: 0.6),
          left: BorderSide(color: WideAgendaColors.grid, width: 0.6),
        ),
      ),
      child: Column(
        children: [
          for (final item in items.take(2))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _PlannerChip(
                  item: item,
                  day: day,
                  controller: widget.controller,
                ),
              ),
            ),
          if (items.length > 2)
            Text(
              '+${items.length - 2}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: WideAgendaColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fase do ciclo (ou semana da gestação) na faixa "dia todo".
class _BandChip extends StatelessWidget {
  final WomenBand band;

  const _BandChip({required this.band});

  @override
  Widget build(BuildContext context) {
    final (fill, text, dot) = switch (band.label) {
      'Menstruação' => (
        CycleColors.menstruationFill,
        CycleColors.menstruationText,
        PabColors.menstruation,
      ),
      'Fértil' || 'Ovulação' => (
        CycleColors.fertileFill,
        CycleColors.fertileText,
        PabColors.fertile,
      ),
      _ => (PabColors.track, PabColors.muted, const Color(0xFFAE9FB3)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _LightChip(
        fill: fill,
        dot: dot,
        textColor: text,
        text: band.label,
      ),
    );
  }
}

/// Chip claro da faixa "dia todo": bolinha da cor e texto.
class _LightChip extends StatelessWidget {
  final Color fill;
  final Color dot;
  final Color textColor;
  final String text;

  const _LightChip({
    required this.fill,
    required this.dot,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco de um item do planner, na cor do tipo. Tarefa, meta e anotação
/// têm o check de "feito no dia" no começo, como no planner do celular.
class _PlannerChip extends StatelessWidget {
  final ActivityModel item;
  final DateTime day;
  final UserWideCalendarController controller;
  final bool showTime;

  const _PlannerChip({
    required this.item,
    required this.day,
    required this.controller,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final done = item.isCompleted;
    final (color, icon, label) = switch (item.type) {
      'goal' => (_PlannerColors.goal, Icons.flag_outlined, 'Meta'),
      'note' => (_PlannerColors.note, Icons.note_outlined, 'Anotação'),
      'appointment' => (_PlannerColors.appointment, Icons.person, 'Consulta'),
      _ => (_PlannerColors.task, Icons.check_circle_outline, 'Tarefa'),
    };
    final appointment = item.type == 'appointment';
    final checkable = !appointment;
    final fill = appointment
        ? PabColors.ink
        : Color.alphaBlend(color.withValues(alpha: 0.16), Colors.white);
    final textColor = appointment
        ? Colors.white
        : done
        ? PabColors.muted
        : PabColors.ink;
    final time = item.dueAt == null
        ? ''
        : '${wideTwo(item.dueAt!.hour)}:${wideTwo(item.dueAt!.minute)} ';
    final title = appointment ? 'Consulta' : item.name;

    return Tooltip(
      message: '$label: ${item.name}',
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => controller.openItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                if (checkable)
                  Tooltip(
                    message: done ? 'Desmarcar' : 'Marcar como feito',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => controller.toggleDone(item, day),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: done
                            ? Icon(Icons.check_circle, size: 15, color: color)
                            : Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  )
                else
                  Icon(icon, size: 13, color: textColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${showTime ? time : ''}$title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      decoration: checkable && done
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: textColor,
                    ),
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

/// Humor registrado no dia. Ao passar o mouse, mostra o nome do humor.
class _DayMood extends StatelessWidget {
  final WomenMood? mood;
  final double size;

  const _DayMood({required this.mood, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final mood = this.mood;
    return SizedBox(
      height: size + 6,
      child: mood == null
          ? null
          : Tooltip(
              message: 'Humor: ${mood.label}',
              child: Text(mood.emoji, style: TextStyle(fontSize: size)),
            ),
    );
  }
}

/// Feriado na faixa "dia todo": não tem check nem detalhes.
class _HolidayChip extends StatelessWidget {
  final String name;

  const _HolidayChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Feriado: $name',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: _LightChip(
          fill: const Color(0xFFFFF1D6),
          dot: _PlannerColors.note,
          textColor: _PlannerColors.noteText,
          text: name,
        ),
      ),
    );
  }
}

/// Abre a conexão com o calendário, na coluna do computador e nos filtros do
/// celular.
class _ConnectCalendarButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConnectCalendarButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: Colors.white,
          foregroundColor: PabColors.ink,
          side: const BorderSide(color: PabColors.lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.link_rounded, size: 20),
        label: const Text(
          'Conectar ao calendário',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Botão "Apagar tarefas feitas", na coluna do computador e nos filtros do
/// celular.
class _DeleteDoneTasksButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteDoneTasksButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: Colors.white,
          foregroundColor: PabColors.error,
          side: const BorderSide(color: PabColors.errorLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: const Text(
          'Apagar tarefas feitas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ mês

class _UserMonthView extends StatelessWidget {
  final UserWideCalendarController controller;

  /// Celular: bolinhas coloridas no lugar das etiquetas "2 tarefas".
  const _UserMonthView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final start = controller.rangeStart;
    final month = controller.focusDate.month;

    return Column(
      children: [
        Row(
          children: [
            for (final label in wideWeekdayShort)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WideAgendaColors.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: WideAgendaColors.grid),
                left: BorderSide(color: WideAgendaColors.grid),
              ),
            ),
            child: Column(
              children: [
                for (var week = 0; week < 6; week++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _dayCell(
                              DateTime(
                                start.year,
                                start.month,
                                start.day + week * 7 + d,
                              ),
                              month,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayCell(DateTime day, int month) {
    final c = controller.countsOn(day);
    final holiday = controller.holidayOn(day);
    final pills = [
      if (holiday != null) _pill(holiday, _PlannerColors.holiday, Colors.white),
      if (c.appointments > 0)
        _pill(
          '${c.appointments} ${c.appointments == 1 ? 'consulta' : 'consultas'}',
          _PlannerColors.appointment,
          Colors.white,
        ),
      if (c.tasks > 0)
        _pill(
          '${c.tasks} ${c.tasks == 1 ? 'tarefa' : 'tarefas'}',
          _PlannerColors.task,
          Colors.white,
        ),
      if (c.notes > 0)
        _pill(
          '${c.notes} ${c.notes == 1 ? 'anotação' : 'anotações'}',
          _PlannerColors.note,
          _PlannerColors.noteText,
        ),
      if (c.goals > 0)
        _pill(
          '${c.goals} ${c.goals == 1 ? 'meta' : 'metas'}',
          _PlannerColors.goal,
          Colors.white,
        ),
    ];

    return InkWell(
      onTap: () => controller.openDay(day),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: WomenHealthController.to
              .bandOn(day)
              ?.color
              .withValues(alpha: 0.45),
          border: const Border(
            right: BorderSide(color: WideAgendaColors.grid),
            bottom: BorderSide(color: WideAgendaColors.grid),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WideDayNumber(day: day, faded: day.month != month),
                  if (WomenHealthController.to.moodOn(day) case final mood?)
                    _DayMood(mood: mood, size: 15),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ClipRect(
                child: Wrap(spacing: 3, runSpacing: 3, children: pills),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fill, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ ano

class _UserYearView extends StatelessWidget {
  final UserWideCalendarController controller;

  const _UserYearView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final year = controller.focusDate.year;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                  ? 3
                  : 2;
              return GridView.builder(
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 24,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, i) => _month(DateTime(year, i + 1, 1)),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          children: [
            _legend(_PlannerColors.appointment, 'consulta'),
            _legend(_PlannerColors.task, 'tarefas'),
            _legend(_PlannerColors.note, 'anotações'),
            _legend(_PlannerColors.goal, 'metas'),
            if (controller.showHolidays)
              _legend(_PlannerColors.holiday, 'feriados'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: WideAgendaColors.text),
      ),
    ],
  );

  Widget _month(DateTime first) {
    final start = ProfessionalWideCalendarController.weekStart(first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ProfessionalWideCalendarController.monthNames[first.month - 1],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: WideAgendaColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final label in wideWeekdayInitials)
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WideAgendaColors.text,
                    ),
                  ),
                ),
              for (var i = 0; i < 42; i++)
                _day(
                  DateTime(start.year, start.month, start.day + i),
                  first.month,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _day(DateTime day, int month) {
    if (day.month != month) return const SizedBox.shrink();

    final c = controller.countsOn(day);
    final fill = c.appointments > 0
        ? _PlannerColors.appointment
        : controller.holidayOn(day) != null
        ? _PlannerColors.holiday
        : c.tasks > 0
        ? _PlannerColors.task
        : c.notes > 0
        ? _PlannerColors.note
        : c.goals > 0
        ? _PlannerColors.goal
        : null;
    final isToday = wideSameDay(day, DateTime.now());
    final tint = fill == null
        ? cycleTintOn(WomenHealthController.to, day)
        : null;

    return InkWell(
      onTap: () => controller.openDay(day),
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill ?? tint,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: WideAgendaColors.text, width: 2)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: fill == null
                ? WideAgendaColors.text
                : fill == _PlannerColors.note
                ? _PlannerColors.noteText
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
