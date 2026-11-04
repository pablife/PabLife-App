import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../women_health/widgets/women_health_card.dart';
import '../../women_health/widgets/women_health_summary.dart';
import '../../women_health/women_health_controller.dart';
import '../../women_health/women_health_data.dart';
import '../controllers/professional_wide_calendar_controller.dart';
import '../controllers/user_wide_calendar_controller.dart';
import '../widgets/wide_agenda_views.dart';

/// Cores dos itens do planner (as mesmas do celular).
abstract final class _PlannerColors {
  static const task = AppColor(0xFF00C2A8);
  static const goal = AppColor(0xFF92CA4F);
  static const note = AppColor(0xFFD2CC61);
  static const noteText = AppColor(0xFF3D3A10);
  static const appointment = AppColor(0xFF3065FF);
  static const holiday = AppColor(0xFFE0567A);
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
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: _SideColumn(controller: controller, women: women),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _WithWomenHealth(
                      women: women,
                      panelHeight: 680,
                      panel: Container(
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
                                  _UserWeekView(controller: controller),
                                WideAgendaView.month => _UserMonthView(
                                  controller: controller,
                                ),
                                WideAgendaView.year => _UserYearView(
                                  controller: controller,
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
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

/// Com o modo Saúde da mulher ativo, a agenda fica entre o resumo e o
/// check-in, numa página com rolagem.
class _WithWomenHealth extends StatelessWidget {
  final WomenHealthController women;
  final Widget panel;
  final double panelHeight;

  /// Cartão do modo no celular, acima da agenda.
  final Widget? header;

  const _WithWomenHealth({
    required this.women,
    required this.panel,
    required this.panelHeight,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (!women.isActive) {
      if (header == null) return panel;
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: header),
          Expanded(child: panel),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        header == null ? 0 : 8,
        header == null ? 0 : 8,
        header == null ? 0 : 8,
        header == null ? 16 : 110,
      ),
      children: [
        if (header != null) ...[header!, const SizedBox(height: 12)],
        WomenHealthSummary(controller: women),
        const SizedBox(height: 12),
        SizedBox(height: panelHeight, child: panel),
        const SizedBox(height: 12),
        WomenHealthCareSection(controller: women),
      ],
    );
  }
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
      backgroundColor: WideAgendaColors.background,
      // Mais alto que o normal para não ficar em cima da barra de baixo.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          tooltip: 'Criar',
          backgroundColor: WideAgendaColors.accent,
          foregroundColor: Colors.white,
          onPressed: () => _showCreateSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _WithWomenHealth(
          women: women,
          panelHeight: 620,
          header: WomenHealthCard(controller: women),
          panel: Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            decoration: const BoxDecoration(
              color: WideAgendaColors.panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: controller.goToday,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WideAgendaColors.text,
                        side: const BorderSide(color: WideAgendaColors.text),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Hoje'),
                    ),
                    IconButton(
                      tooltip: 'Anterior',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.move(-1),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: WideAgendaColors.text,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próximo',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.move(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: WideAgendaColors.text,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        controller.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: WideAgendaColors.text,
                        ),
                      ),
                    ),
                    if (controller.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WideAgendaColors.text,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Mostrar',
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(
                        Icons.filter_list,
                        color: WideAgendaColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<WideAgendaView>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: WideAgendaView.day,
                        label: Text('Dia'),
                      ),
                      ButtonSegment(
                        value: WideAgendaView.week,
                        label: Text('Semana'),
                      ),
                      ButtonSegment(
                        value: WideAgendaView.month,
                        label: Text('Mês'),
                      ),
                      ButtonSegment(
                        value: WideAgendaView.year,
                        label: Text('Ano'),
                      ),
                    ],
                    selected: {controller.view},
                    onSelectionChanged: (s) => controller.setView(s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
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
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: switch (controller.view) {
                    WideAgendaView.day || WideAgendaView.week => _UserWeekView(
                      controller: controller,
                      compact: true,
                    ),
                    WideAgendaView.month => _UserMonthView(
                      controller: controller,
                      compact: true,
                    ),
                    WideAgendaView.year => _UserYearView(
                      controller: controller,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
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
                  if (women.isActive)
                    WideFilterRow(
                      label: women.trail!.title,
                      color: _PlannerColors.women,
                      value: women.showBand,
                      count: c.weekDays.length,
                      onChanged: (value) {
                        women.setShowBand(value);
                        c.update();
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

// ------------------------------------------------------------ coluna lateral

class _SideColumn extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController women;

  const _SideColumn({required this.controller, required this.women});

  @override
  Widget build(BuildContext context) {
    final totals = controller.totals;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Criar',
            position: PopupMenuPosition.under,
            color: Colors.white,
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: WideAgendaColors.accent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Criar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
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
                if (women.isActive)
                  WideFilterRow(
                    label: women.trail!.title,
                    color: _PlannerColors.women,
                    value: women.showBand,
                    count: controller.weekDays.length,
                    onChanged: women.setShowBand,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _DeleteDoneTasksButton(
            onPressed: () => controller.deleteDoneTasks(context),
          ),
          const SizedBox(height: 16),
          WomenHealthCard(controller: women),
          const SizedBox(height: 16),
          _card(
            child: const Text(
              'Clique numa tarefa, meta ou anotação para ver os detalhes. '
              'Clique numa consulta para remarcar, cancelar ou falar com o '
              'profissional.',
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
          Text(label, style: const TextStyle(color: WideAgendaColors.text)),
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

// ------------------------------------------------------------------ semana

class _UserWeekView extends StatefulWidget {
  final UserWideCalendarController controller;

  /// Celular: coluna das horas mais estreita.
  final bool compact;

  const _UserWeekView({required this.controller, this.compact = false});

  @override
  State<_UserWeekView> createState() => _UserWeekViewState();
}

class _UserWeekViewState extends State<_UserWeekView> {
  static const _hourHeight = 60.0;

  double get _gutter => widget.compact ? 40 : 56;

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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WideAgendaColors.text,
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
        // Fase do ciclo, semana da gestação ou sintoma (Saúde da mulher).
        if (days.any((day) => women.bandOn(day) != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: _gutter),
                for (final day in days)
                  Expanded(child: _bandCell(women.bandOn(day))),
              ],
            ),
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
                      color: WideAgendaColors.text,
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
                                widget.compact
                                    ? wideTwo(hour)
                                    : '${wideTwo(hour)}:00',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: WideAgendaColors.text,
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

  Widget _bandCell(WomenBand? band) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: band?.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: band == null
          ? null
          : Text(
              band.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: band.textColor,
              ),
            ),
    );
  }

  Widget _dayColumn(DateTime day, List<ActivityModel> items) {
    final isToday = wideSameDay(day, DateTime.now());
    return Container(
      color: isToday ? Colors.white.withValues(alpha: 0.25) : null,
      child: Column(
        children: [
          for (var hour = 0; hour < 24; hour++)
            _hourCell(day, items.where((a) => a.dueAt!.hour == hour).toList()),
        ],
      ),
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
                color: WideAgendaColors.text,
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
    final (color, textColor, icon, label) = switch (item.type) {
      'goal' => (
        _PlannerColors.goal,
        Colors.white,
        Icons.flag_outlined,
        'Meta',
      ),
      'note' => (
        _PlannerColors.note,
        _PlannerColors.noteText,
        Icons.note_outlined,
        'Anotação',
      ),
      'appointment' => (
        _PlannerColors.appointment,
        Colors.white,
        Icons.person,
        'Consulta',
      ),
      _ => (
        // Tarefa feita fica mais escura, como no celular.
        done ? const AppColor(0xFF0C8DA1) : _PlannerColors.task,
        Colors.white,
        Icons.check_circle_outline,
        'Tarefa',
      ),
    };
    final checkable = item.type != 'appointment';
    final time = item.dueAt == null
        ? ''
        : '${wideTwo(item.dueAt!.hour)}:${wideTwo(item.dueAt!.minute)} ';
    final title = item.type == 'appointment' ? 'Consulta' : item.name;

    return Tooltip(
      message: '$label: ${item.name}',
      child: Material(
        color: color,
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
                        child: Icon(
                          done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: textColor,
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
                      fontWeight: FontWeight.w600,
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
      child: Container(
        height: 24,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _PlannerColors.holiday,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const AppColor(0xFFD32F2F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.delete_outline, size: 20),
        label: const Text(
          'Apagar tarefas feitas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ mês

class _UserMonthView extends StatelessWidget {
  final UserWideCalendarController controller;

  /// Celular: bolinhas coloridas no lugar das etiquetas "2 tarefas".
  final bool compact;

  const _UserMonthView({required this.controller, this.compact = false});

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
    if (compact) return _compactDayCell(day, month, c);
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

  Widget _compactDayCell(DateTime day, int month, UserDayCounts c) {
    final dots = [
      if (controller.holidayOn(day) != null) _PlannerColors.holiday,
      if (c.appointments > 0) _PlannerColors.appointment,
      if (c.tasks > 0) _PlannerColors.task,
      if (c.notes > 0) _PlannerColors.note,
      if (c.goals > 0) _PlannerColors.goal,
    ];

    return InkWell(
      onTap: () => controller.openDay(day),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
          children: [
            WideDayNumber(day: day, faded: day.month != month),
            if (WomenHealthController.to.moodOn(day) case final mood?)
              _DayMood(mood: mood, size: 14),
            const SizedBox(height: 4),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              alignment: WrapAlignment.center,
              children: [
                for (final color in dots)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
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

    return InkWell(
      onTap: () => controller.openDay(day),
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: WideAgendaColors.text, width: 2)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
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
