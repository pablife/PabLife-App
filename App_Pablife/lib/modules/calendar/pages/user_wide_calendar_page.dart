import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../controllers/professional_wide_calendar_controller.dart';
import '../controllers/user_wide_calendar_controller.dart';
import '../widgets/wide_agenda_views.dart';

/// Cores dos itens do planner (as mesmas do celular).
abstract final class _PlannerColors {
  static const task = Color(0xFF00C2A8);
  static const goal = Color(0xFF92CA4F);
  static const note = Color(0xFFD2CC61);
  static const noteText = Color(0xFF3D3A10);
  static const appointment = Color(0xFF3065FF);
}

/// Agenda do usuário no computador: "+ Criar", minicalendário e filtros à
/// esquerda; semana, mês ou ano à direita.
class UserWideCalendarPage extends StatelessWidget {
  const UserWideCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserWideCalendarController>(
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ coluna lateral

class _SideColumn extends StatelessWidget {
  final UserWideCalendarController controller;

  const _SideColumn({required this.controller});

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
                color: WideAgendaColors.appointment,
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
              ],
            ),
          ),
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

  const _UserWeekView({required this.controller});

  @override
  State<_UserWeekView> createState() => _UserWeekViewState();
}

class _UserWeekViewState extends State<_UserWeekView> {
  static const _hourHeight = 60.0;
  static const _gutter = 56.0;

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

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: _gutter),
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
              const SizedBox(
                width: _gutter,
                child: Padding(
                  padding: EdgeInsets.only(right: 8, top: 4),
                  child: Text(
                    'dia todo',
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
        done ? const Color(0xFF0C8DA1) : _PlannerColors.task,
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

// ------------------------------------------------------------------ mês

class _UserMonthView extends StatelessWidget {
  final UserWideCalendarController controller;

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
    final pills = [
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
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: WideAgendaColors.grid),
            bottom: BorderSide(color: WideAgendaColors.grid),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: WideDayNumber(day: day, faded: day.month != month),
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
              final columns = constraints.maxWidth > 900 ? 4 : 3;
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
