import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../women_health/women_health_controller.dart';
import '../../women_health/women_health_data.dart';
import '../controllers/professional_wide_calendar_controller.dart';
import '../controllers/user_wide_calendar_controller.dart';
import 'wide_agenda_views.dart';

/// Cores das categorias na agenda do celular (canvas "Agenda — mobile").
abstract final class PhoneAgendaColors {
  static const task = AppColor(0xFF00C2A8);
  static const goal = Color(0xFF8D84F0);
  static const note = Color(0xFFE0A526);
  static const noteText = Color(0xFF6B4A00);
  static const appointment = PabColors.ink;
  static const holiday = Color(0xFFD63A74);
  static const grid = AppColor.pair(0xFFE4ECEC, 0xFFF0E4EC);
  static const gridSoft = AppColor.pair(0xFFEDF2F2, 0xFFF6EDF3);
  static const hourText = AppColor.pair(0xFF4A5E60, 0xFF5E4A66);
}

/// Cores do ciclo nos calendários e na faixa "dia todo" (canvas).
abstract final class CycleColors {
  static const menstruationFill = Color(0xFFFCE8F3);
  static const menstruationText = Color(0xFF7A1F52);
  static const fertileFill = Color(0xFFEEEDFF);
  static const fertileText = Color(0xFF3F3A8C);
}

/// Quem acompanha o ciclo (não gestação nem menopausa).
bool tracksCycle(WomenHealthController? women) =>
    women != null &&
    women.isActive &&
    women.lastPeriod != null &&
    women.trail != WomenTrail.pregnancy &&
    women.trail != WomenTrail.menopause;

/// Círculo do ciclo nos calendários: menstruação e período fértil.
Color? cycleTintOn(WomenHealthController? women, DateTime day) {
  if (!tracksCycle(women) || !women!.showBand) return null;
  return switch (women.cyclePhaseOn(day)?.kind) {
    WomenCycleKind.menstruation => CycleColors.menstruationFill,
    WomenCycleKind.fertile => CycleColors.fertileFill,
    _ => null,
  };
}

/// Legenda dos círculos do ciclo.
class CycleLegend extends StatelessWidget {
  const CycleLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PabColors.muted,
          ),
        ),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item(CycleColors.menstruationFill, 'Menstruação'),
        item(CycleColors.fertileFill, 'Fértil (previsto)'),
      ],
    );
  }
}

const _weekLetters = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
const _weekShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _same(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

({Color bg, Color fg, String label}) _look(ActivityModel item) =>
    switch (item.type) {
      'goal' => (bg: PhoneAgendaColors.goal, fg: Colors.white, label: 'Meta'),
      'note' => (
        bg: PhoneAgendaColors.note,
        fg: PhoneAgendaColors.noteText,
        label: 'Anotação',
      ),
      'appointment' => (
        bg: PhoneAgendaColors.appointment,
        fg: Colors.white,
        label: 'Consulta',
      ),
      _ => (bg: PhoneAgendaColors.task, fg: Colors.white, label: 'Tarefa'),
    };

String _title(ActivityModel item) =>
    item.type == 'appointment' ? 'Consulta' : item.name;

String _time(DateTime d) => '${wideTwo(d.hour)}:${wideTwo(d.minute)}';

/// Minutos que o bloco ocupa na grade de horas.
int _minutes(ActivityModel item) => item.type == 'appointment' ? 50 : 30;

/// Primeira e última hora da grade: 7h às 21h, ou mais se houver itens fora.
(int, int) _hourRange(Iterable<ActivityModel> items) {
  var first = 7;
  var last = 21;
  for (final item in items) {
    final due = item.dueAt;
    if (due == null || item.allDay) continue;
    first = math.min(first, due.hour);
    last = math.max(last, math.min(24, due.hour + 1));
  }
  return (first, last);
}

/// Linha "agora" que anda com o relógio.
class _NowTicker extends StatefulWidget {
  final Widget Function(DateTime now) builder;

  const _NowTicker({required this.builder});

  @override
  State<_NowTicker> createState() => _NowTickerState();
}

class _NowTickerState extends State<_NowTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(DateTime.now());
}

// ------------------------------------------------------------------- Dia

/// Visão Dia: faixa da semana, itens do dia todo e a grade de horas.
class PhoneDayView extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController? women;

  const PhoneDayView({super.key, required this.controller, this.women});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final day = c.focusDate;
    final items = c.eventsOn(day);
    final allDay = items.where((e) => e.allDay || e.dueAt == null).toList();
    final timed = items.where((e) => !e.allDay && e.dueAt != null).toList();
    final holiday = c.holidayOn(day);
    final band = women?.bandOn(day);
    final (first, last) = _hourRange(timed);
    const hourHeight = 56.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final d in c.stripDays) ...[
              if (d != c.stripDays.first) const SizedBox(width: 4),
              Expanded(
                child: _StripDay(
                  day: d,
                  selected: _same(d, day),
                  hasItems: c.eventsOn(d).isNotEmpty || c.holidayOn(d) != null,
                  onTap: () => c.openDay(d),
                ),
              ),
            ],
          ],
        ),
        if (holiday != null || band != null || allDay.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (holiday != null)
            _AllDayRow(
              label: holiday,
              tag: 'Feriado',
              dot: PhoneAgendaColors.holiday,
              background: PhoneAgendaColors.holiday.withValues(alpha: 0.1),
              foreground: const Color(0xFF8C1D45),
            ),
          if (band != null)
            _AllDayRow(
              label: band.label,
              tag: women!.trail!.title,
              dot: band.color,
              background: band.color.withValues(alpha: 0.25),
              foreground: PabColors.ink,
            ),
          for (final item in allDay)
            _AllDayRow(
              label: _title(item),
              tag: _look(item).label,
              dot: _look(item).bg,
              background: _look(item).bg.withValues(alpha: 0.14),
              foreground: PabColors.ink,
              done: item.type != 'appointment' && item.isCompleted,
              onTap: () => c.openItem(item),
              onCheck: item.type == 'appointment'
                  ? null
                  : () => c.toggleDone(item, day),
            ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
          decoration: BoxDecoration(
            color: PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  children: [
                    for (var h = first; h < last; h++)
                      SizedBox(
                        height: hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Transform.translate(
                            offset: const Offset(0, -7),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '${wideTwo(h)}:00',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PhoneAgendaColors.hourText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: (last - first) * hourHeight,
                  child: _NowTicker(
                    builder: (now) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var h = 0; h < last - first; h++)
                          Positioned(
                            top: h * hourHeight,
                            left: 0,
                            right: 0,
                            child: const Divider(
                              height: 1,
                              thickness: 1,
                              color: PhoneAgendaColors.grid,
                            ),
                          ),
                        for (final item in timed)
                          _TimedBlock(
                            item: item,
                            top:
                                ((item.dueAt!.hour - first) * 60 +
                                    item.dueAt!.minute) /
                                60 *
                                hourHeight,
                            height: math.max(
                              46,
                              _minutes(item) / 60 * hourHeight,
                            ),
                            onTap: () => c.openItem(item),
                          ),
                        if (_same(now, day) &&
                            now.hour >= first &&
                            now.hour < last)
                          Positioned(
                            top:
                                ((now.hour - first) * 60 + now.minute) /
                                60 *
                                hourHeight,
                            left: 0,
                            right: 0,
                            child: const _NowLine(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty && holiday == null) ...[
          const SizedBox(height: 10),
          const Text(
            'Nada marcado para este dia. Toque em + para criar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: PabColors.muted),
          ),
        ],
      ],
    );
  }
}

class _StripDay extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final bool hasItems;
  final VoidCallback onTap;

  const _StripDay({
    required this.day,
    required this.selected,
    required this.hasItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = _same(day, DateTime.now());
    return Semantics(
      button: true,
      selected: selected,
      label: '${_weekShort[day.weekday % 7]}, dia ${day.day}',
      excludeSemantics: true,
      child: Material(
        color: selected ? PabColors.ink : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? PabColors.ink
                : today
                ? PabColors.accent
                : PabColors.line,
            width: today && !selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekLetters[day.weekday % 7],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? PabColors.onInkSoft : PabColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : PabColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasItems
                        ? (selected ? PabColors.accent : PabColors.accentText)
                        : Colors.transparent,
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

class _AllDayRow extends StatelessWidget {
  final String label;
  final String tag;
  final Color dot;
  final Color background;
  final Color foreground;
  final bool done;
  final VoidCallback? onTap;
  final VoidCallback? onCheck;

  const _AllDayRow({
    required this.label,
    required this.tag,
    required this.dot,
    required this.background,
    required this.foreground,
    this.done = false,
    this.onTap,
    this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (onCheck != null)
                    Tooltip(
                      message: done ? 'Desmarcar' : 'Marcar como feito',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onCheck,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: dot,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimedBlock extends StatelessWidget {
  final ActivityModel item;
  final double top;
  final double height;
  final VoidCallback onTap;

  const _TimedBlock({
    required this.item,
    required this.top,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final look = _look(item);
    final done = item.type != 'appointment' && item.isCompleted;
    return Positioned(
      top: top,
      left: 4,
      right: 0,
      height: height,
      child: Material(
        color: look.bg.withValues(alpha: done ? 0.55 : 1),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_time(item.dueAt!)} · ${_title(item)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: look.fg,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: look.fg,
                  ),
                ),
                if (height >= 60)
                  Text(
                    look.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: look.fg.withValues(alpha: 0.85),
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

class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// ---------------------------------------------------------------- Semana

/// Visão Semana: cabeçalho dos dias, linha do dia todo e grade de horas.
class PhoneWeekView extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController? women;

  const PhoneWeekView({super.key, required this.controller, this.women});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final days = c.weekDays;
    final timedByDay = {
      for (final d in days)
        d: c.eventsOn(d).where((e) => !e.allDay && e.dueAt != null).toList(),
    };
    final (first, last) = _hourRange(timedByDay.values.expand((e) => e));
    const hourHeight = 44.0;
    const labelWidth = 36.0;

    Color columnColor(DateTime d) => _same(d, DateTime.now())
        ? PabColors.accent.withValues(alpha: 0.07)
        : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 6, 10),
          decoration: BoxDecoration(
            color: PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dias: tocar abre o dia com as horas.
              Row(
                children: [
                  const SizedBox(width: labelWidth),
                  for (final d in days)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Abrir ${_weekShort[d.weekday % 7]}, ${d.day}',
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => c.openDay(d),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              children: [
                                Text(
                                  _weekLetters[d.weekday % 7],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: PabColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _same(d, DateTime.now())
                                        ? PabColors.accent
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    '${d.day}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: PabColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: PhoneAgendaColors.grid),
              // Dia todo: feriados, faixa da trilha e itens sem hora.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      width: labelWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 6, 4, 6),
                        child: Text(
                          'dia todo',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 9,
                            color: PhoneAgendaColors.hourText,
                          ),
                        ),
                      ),
                    ),
                    for (final d in days)
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 26),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: columnColor(d),
                            border: const Border(
                              left: BorderSide(
                                color: PhoneAgendaColors.gridSoft,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final color in [
                                if (c.holidayOn(d) != null)
                                  PhoneAgendaColors.holiday,
                                if (women?.bandOn(d) case final band?)
                                  band.color,
                                for (final e
                                    in c
                                        .eventsOn(d)
                                        .where(
                                          (e) => e.allDay || e.dueAt == null,
                                        ))
                                  _look(e).bg,
                              ])
                                Container(
                                  height: 6,
                                  margin: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: PhoneAgendaColors.grid),
              SizedBox(
                height: (last - first) * hourHeight,
                child: _NowTicker(
                  builder: (now) => Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Column(
                          children: [
                            for (var h = first; h < last; h++)
                              SizedBox(
                                height: hourHeight,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 4,
                                      top: 2,
                                    ),
                                    child: Text(
                                      wideTwo(h),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: PhoneAgendaColors.hourText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final d in days)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: columnColor(d),
                              border: const Border(
                                left: BorderSide(
                                  color: PhoneAgendaColors.gridSoft,
                                ),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var h = 1; h < last - first; h++)
                                  Positioned(
                                    top: h * hourHeight,
                                    left: 0,
                                    right: 0,
                                    child: const Divider(
                                      height: 1,
                                      color: PhoneAgendaColors.grid,
                                    ),
                                  ),
                                for (final item in timedByDay[d]!)
                                  Positioned(
                                    top:
                                        ((item.dueAt!.hour - first) * 60 +
                                            item.dueAt!.minute) /
                                        60 *
                                        hourHeight,
                                    left: 2,
                                    right: 2,
                                    height: math.max(
                                      22,
                                      _minutes(item) / 60 * hourHeight,
                                    ),
                                    child: Tooltip(
                                      message:
                                          '${_look(item).label}: ${_title(item)}',
                                      child: Material(
                                        color: _look(item).bg,
                                        borderRadius: BorderRadius.circular(7),
                                        child: InkWell(
                                          onTap: () => c.openItem(item),
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: Text(
                                              _time(item.dueAt!),
                                              maxLines: 1,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: _look(item).fg,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_same(now, d) &&
                                    now.hour >= first &&
                                    now.hour < last)
                                  Positioned(
                                    top:
                                        ((now.hour - first) * 60 + now.minute) /
                                        60 *
                                        hourHeight,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      color: PabColors.pink,
                                    ),
                                  ),
                              ],
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
        const SizedBox(height: 8),
        const Text(
          'Toque num dia para ver o plano com as horas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: PabColors.muted),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- Mês

/// Visão Mês: cada dia com pontinhos das categorias marcadas nele.
class PhoneMonthView extends StatelessWidget {
  final UserWideCalendarController controller;
  final WomenHealthController? women;

  const PhoneMonthView({super.key, required this.controller, this.women});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final month = c.focusDate;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = _dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final w in _weekShort)
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PabColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: () {
                          final n = r * 7 + col - leading + 1;
                          if (n < 1 || n > daysInMonth) {
                            return const SizedBox(height: 54);
                          }
                          final day = DateTime(month.year, month.month, n);
                          final counts = c.countsOn(day);
                          final tint = cycleTintOn(women, day);
                          final dots = <Color>[
                            if (c.holidayOn(day) != null)
                              PhoneAgendaColors.holiday,
                            if (counts.appointments > 0)
                              PhoneAgendaColors.appointment,
                            if (counts.tasks > 0) PhoneAgendaColors.task,
                            if (counts.goals > 0) PhoneAgendaColors.goal,
                            if (counts.notes > 0) PhoneAgendaColors.note,
                          ];
                          final isToday = day == today;
                          return Semantics(
                            button: true,
                            label: 'Dia $n',
                            excludeSemantics: true,
                            child: Material(
                              color: isToday
                                  ? PabColors.accent.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isToday
                                      ? PabColors.accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => c.openDay(day),
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 56,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: tint,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$n',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                            color: PabColors.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SizedBox(
                                        height: 5,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (final dot in dots.take(4))
                                              Container(
                                                width: 5,
                                                height: 5,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: dot,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                      ),
                    ),
                ],
              ),
            ),
          if (tracksCycle(women) && women!.showBand) ...[
            const SizedBox(height: 6),
            const Align(alignment: Alignment.centerLeft, child: CycleLegend()),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- Ano

/// Visão Ano: os doze meses; dias com algo marcado ficam destacados.
class PhoneYearView extends StatelessWidget {
  final UserWideCalendarController controller;

  const PhoneYearView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final year = c.focusDate.year;
    final today = _dateOnly(DateTime.now());
    const names = ProfessionalWideCalendarController.monthNames;
    final women = Get.isRegistered<WomenHealthController>()
        ? WomenHealthController.to
        : null;
    final cycle = tracksCycle(women) && women!.showBand;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var m = 1; m <= 12; m++)
              SizedBox(
                width: width,
                child: _MiniMonth(
                  title: names[m - 1],
                  month: DateTime(year, m, 1),
                  today: today,
                  marked: (day) {
                    final counts = c.countsOn(day);
                    return counts.tasks +
                            counts.goals +
                            counts.notes +
                            counts.appointments >
                        0;
                  },
                  tint: cycle ? (day) => cycleTintOn(women, day) : null,
                  onTap: () => c.openMonth(DateTime(year, m, 1)),
                ),
              ),
            if (cycle) const CycleLegend(),
          ],
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final String title;
  final DateTime month;
  final DateTime today;
  final bool Function(DateTime) marked;
  final Color? Function(DateTime)? tint;
  final VoidCallback onTap;

  const _MiniMonth({
    required this.title,
    required this.month,
    required this.today,
    required this.marked,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = month.year == today.year && month.month == today.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = month.weekday % 7;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Semantics(
      button: true,
      label: 'Abrir $title',
      excludeSemantics: true,
      child: Material(
        color: PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrent ? PabColors.accent : PabColors.line,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? PabColors.accentText : PabColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (var r = 0; r < rows; r++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: () {
                            final n = r * 7 + col - leading + 1;
                            if (n < 1 || n > daysInMonth) {
                              return const SizedBox(height: 17);
                            }
                            final day = DateTime(month.year, month.month, n);
                            final isToday = day == today;
                            final has = marked(day);
                            final cycle = tint?.call(day);
                            return Container(
                              height: 17,
                              margin: const EdgeInsets.all(0.5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? PabColors.accent
                                    : cycle ??
                                          (has
                                              ? PabColors.soft
                                              : Colors.transparent),
                              ),
                              child: Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isToday || has
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isToday || cycle != null
                                      ? PabColors.ink
                                      : has
                                      ? PabColors.softText
                                      : PabColors.muted,
                                ),
                              ),
                            );
                          }(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
