import 'package:flutter/material.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../controllers/professional_wide_calendar_controller.dart';

/// Cores da agenda do computador (as mesmas da agenda do celular).
abstract final class WideAgendaColors {
  static const background = Color(0xFF00343C);
  static const panel = Color(0xFFC1CDFF);
  static const text = Color(0xFF00343C);
  static const grid = Color(0xFFA9B6EA);
  static const appointment = Color(0xFF3065FF);
  static const free = Color(0xFF0C8DA1);
  static const freeFill = Color(0xFFE7F6F7);
  static const freeText = Color(0xFF0C6B7A);
  static const completed = Color(0xFF0C8DA1);
  static const ongoing = Color(0xFF00C2A8);
  static const cancelled = Color(0xFF8E99A8);
  static const noShow = Color(0xFFB3A57F);
}

const _weekdayShort = ['DOM.', 'SEG.', 'TER.', 'QUA.', 'QUI.', 'SEX.', 'SÁB.'];
const _weekdayInitials = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int n) => n.toString().padLeft(2, '0');

/// Número do dia; hoje fica num círculo azul.
class _DayNumber extends StatelessWidget {
  final DateTime day;
  final double size;
  final bool faded;

  const _DayNumber({required this.day, this.size = 28, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(day, DateTime.now());
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: isToday
          ? const BoxDecoration(
              color: WideAgendaColors.appointment,
              shape: BoxShape.circle,
            )
          : null,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          color: isToday
              ? Colors.white
              : WideAgendaColors.text.withValues(alpha: faded ? 0.4 : 1),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ semana

class WideWeekView extends StatefulWidget {
  final ProfessionalWideCalendarController controller;

  const WideWeekView({super.key, required this.controller});

  @override
  State<WideWeekView> createState() => _WideWeekViewState();
}

class _WideWeekViewState extends State<WideWeekView> {
  static const _hourHeight = 60.0;
  static const _gutter = 56.0;

  // Abre já na manhã (7h); dá para rolar para cima e para baixo.
  final _scroll = ScrollController(initialScrollOffset: 7 * _hourHeight);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final days = controller.weekDays;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: _gutter),
            for (final day in days)
              Expanded(
                child: InkWell(
                  onTap: () => controller.openDay(day),
                  child: Column(
                    children: [
                      Text(
                        _weekdayShort[day.weekday % 7],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WideAgendaColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DayNumber(day: day, size: 36),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
          ],
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
                                '${_two(hour)}:00',
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
                  Expanded(child: _dayColumn(controller, day)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(
    ProfessionalWideCalendarController controller,
    DateTime day,
  ) {
    final slots = controller.slotsOn(day);
    final isToday = _sameDay(day, DateTime.now());

    return Container(
      color: isToday ? Colors.white.withValues(alpha: 0.25) : null,
      child: Column(
        children: [
          for (var hour = 0; hour < 24; hour++)
            _hourCell(
              controller,
              DateTime(day.year, day.month, day.day, hour),
              slots.where((s) => s.startAt.toLocal().hour == hour).toList(),
            ),
        ],
      ),
    );
  }

  Widget _hourCell(
    ProfessionalWideCalendarController controller,
    DateTime start,
    List<ProfessionalScheduleSlot> items,
  ) {
    // Só dá para liberar horário no futuro, como na janela de novo horário.
    final canCreate = items.isEmpty && start.isAfter(DateTime.now());

    final cell = Container(
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
          for (final slot in items.take(2))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: WideAgendaChip(slot: slot, controller: controller),
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

    if (!canCreate) return cell;
    return Tooltip(
      message: 'Liberar horário às ${_two(start.hour)}:00',
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: () => controller.createSlot(at: start),
        hoverColor: Colors.white.withValues(alpha: 0.35),
        child: cell,
      ),
    );
  }
}

/// Bloco de um horário: livre (contorno verde-água) ou consulta (cheio).
class WideAgendaChip extends StatelessWidget {
  final ProfessionalScheduleSlot slot;
  final ProfessionalWideCalendarController controller;

  const WideAgendaChip({
    super.key,
    required this.slot,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final time = slot.timeLabel;
    final appointment = slot.appointment;

    if (appointment == null) {
      return Tooltip(
        message: slot.isRecurring
            ? 'Horário livre (repete toda semana) — clique para remover'
            : 'Horário livre — clique para remover',
        child: _box(
          onTap: () => controller.removeSlot(slot),
          color: WideAgendaColors.freeFill,
          border: Border.all(color: WideAgendaColors.free, width: 1.5),
          icon: slot.isRecurring ? Icons.repeat : Icons.schedule,
          text: '$time livre',
          textColor: WideAgendaColors.freeText,
        ),
      );
    }

    final (color, status) = switch (appointment.status) {
      AppointmentStatus.cancelled => (WideAgendaColors.cancelled, 'Cancelada'),
      AppointmentStatus.noShow => (WideAgendaColors.noShow, 'Não compareceu'),
      AppointmentStatus.completed => (WideAgendaColors.completed, 'Realizada'),
      _ when appointment.isOngoing => (WideAgendaColors.ongoing, 'Agora'),
      _ => (WideAgendaColors.appointment, 'Agendada'),
    };

    return Tooltip(
      message: 'Consulta com ${appointment.patientName} — $status',
      child: _box(
        onTap: () => controller.openAppointment(appointment),
        color: color,
        icon: Icons.person,
        text: '$time ${appointment.patientName}',
        textColor: Colors.white,
        strike: appointment.status == AppointmentStatus.cancelled,
      ),
    );
  }

  Widget _box({
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
    required String text,
    required Color textColor,
    BoxBorder? border,
    bool strike = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            border: border,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: strike ? TextDecoration.lineThrough : null,
                    decorationColor: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ mês

class WideMonthView extends StatelessWidget {
  final ProfessionalWideCalendarController controller;

  const WideMonthView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final start = controller.rangeStart;
    final month = controller.focusDate.month;

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayShort)
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
    final appointments = controller.showAppointments
        ? controller.appointmentCountOn(day)
        : 0;
    final free = controller.showFree ? controller.freeCountOn(day) : 0;

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
              child: _DayNumber(day: day, faded: day.month != month),
            ),
            const SizedBox(height: 4),
            if (appointments > 0)
              _countPill(
                '$appointments ${appointments == 1 ? 'consulta' : 'consultas'}',
                fill: WideAgendaColors.appointment,
                textColor: Colors.white,
              ),
            if (free > 0) ...[
              const SizedBox(height: 3),
              _countPill(
                '$free ${free == 1 ? 'livre' : 'livres'}',
                fill: WideAgendaColors.freeFill,
                textColor: WideAgendaColors.freeText,
                border: WideAgendaColors.free,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countPill(
    String text, {
    required Color fill,
    required Color textColor,
    Color? border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: border != null ? Border.all(color: border, width: 1.2) : null,
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

class WideYearView extends StatelessWidget {
  final ProfessionalWideCalendarController controller;

  const WideYearView({super.key, required this.controller});

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
        Row(
          children: [
            _legendDot(WideAgendaColors.appointment),
            const Text(
              ' dia com consulta    ',
              style: TextStyle(fontSize: 12, color: WideAgendaColors.text),
            ),
            _legendDot(WideAgendaColors.free),
            const Text(
              ' só horários livres',
              style: TextStyle(fontSize: 12, color: WideAgendaColors.text),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
              for (final label in _weekdayInitials)
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

    final hasAppointment =
        controller.showAppointments && controller.appointmentCountOn(day) > 0;
    final hasFree = controller.showFree && controller.freeCountOn(day) > 0;
    final isToday = _sameDay(day, DateTime.now());
    final fill = hasAppointment
        ? WideAgendaColors.appointment
        : hasFree
        ? WideAgendaColors.free
        : null;

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
            color: fill != null ? Colors.white : WideAgendaColors.text,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- minicalendário

/// Minicalendário da coluna da esquerda: clicar num dia abre a semana dele.
class WideMiniMonth extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayTap;

  const WideMiniMonth({
    super.key,
    required this.initialMonth,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  State<WideMiniMonth> createState() => _WideMiniMonthState();
}

class _WideMiniMonthState extends State<WideMiniMonth> {
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );

  @override
  Widget build(BuildContext context) {
    final start = ProfessionalWideCalendarController.weekStart(_month);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${ProfessionalWideCalendarController.monthNames[_month.month - 1]} de ${_month.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WideAgendaColors.text,
                ),
              ),
            ),
            _arrow(Icons.chevron_left, -1),
            _arrow(Icons.chevron_right, 1),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final label in _weekdayInitials)
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
            for (var i = 0; i < 42; i++) _day(start, i),
          ],
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, int delta) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () =>
          setState(() => _month = DateTime(_month.year, _month.month + delta)),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 20, color: WideAgendaColors.text),
      ),
    );
  }

  Widget _day(DateTime start, int i) {
    final day = DateTime(start.year, start.month, start.day + i);
    final isToday = _sameDay(day, DateTime.now());
    final isSelected = _sameDay(day, widget.selectedDay);
    final faded = day.month != _month.month;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => widget.onDayTap(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isToday ? WideAgendaColors.appointment : null,
          border: isSelected && !isToday
              ? Border.all(color: WideAgendaColors.appointment, width: 1.5)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday
                ? Colors.white
                : WideAgendaColors.text.withValues(alpha: faded ? 0.4 : 1),
          ),
        ),
      ),
    );
  }
}
