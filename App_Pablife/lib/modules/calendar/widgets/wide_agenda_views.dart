import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../controllers/professional_wide_calendar_controller.dart';

/// Cores da agenda do computador (as mesmas da agenda do celular).
abstract final class WideAgendaColors {
  // No modo Saúde da mulher o planner é claro, sobre fundo rosé.
  static const background = AppColor.pair(0xFF00343C, 0xFFF7F1EF);
  static const panel = AppColor.pair(0xFFC1CDFF, 0xFFFFFFFF);
  static const text = AppColor(0xFF00343C);
  static const grid = AppColor.pair(0xFFA9B6EA, 0xFFEADFEA);
  static const appointment = AppColor(0xFF3065FF);
  static const accent = AppColor.pair(0xFF3065FF, 0xFF4A3560);
  static const free = AppColor(0xFF0C8DA1);
  static const freeFill = AppColor(0xFFE7F6F7);
  static const freeText = AppColor(0xFF0C6B7A);
  static const completed = AppColor(0xFF0C8DA1);
  static const ongoing = AppColor(0xFF00C2A8);
  static const cancelled = AppColor(0xFF8E99A8);
  static const noShow = AppColor(0xFFB3A57F);
}

const wideWeekdayShort = [
  'DOM.',
  'SEG.',
  'TER.',
  'QUA.',
  'QUI.',
  'SEX.',
  'SÁB.',
];
const wideWeekdayInitials = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

bool wideSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String wideTwo(int n) => n.toString().padLeft(2, '0');

/// Número do dia; hoje fica num círculo azul.
class WideDayNumber extends StatelessWidget {
  final DateTime day;
  final double size;
  final bool faded;

  const WideDayNumber({
    super.key,
    required this.day,
    this.size = 28,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = wideSameDay(day, DateTime.now());
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
    final isToday = wideSameDay(day, DateTime.now());

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
      message: 'Liberar horário às ${wideTwo(start.hour)}:00',
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
              child: WideDayNumber(day: day, faded: day.month != month),
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

    final hasAppointment =
        controller.showAppointments && controller.appointmentCountOn(day) > 0;
    final hasFree = controller.showFree && controller.freeCountOn(day) > 0;
    final isToday = wideSameDay(day, DateTime.now());
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
    final isToday = wideSameDay(day, DateTime.now());
    final isSelected = wideSameDay(day, widget.selectedDay);
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

/// Linha das caixas "Mostrar" (coluna da esquerda das agendas).
class WideFilterRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final int count;
  final ValueChanged<bool> onChanged;

  const WideFilterRow({
    super.key,
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

/// Cabeçalho das agendas do computador: Hoje, setas, título e
/// Semana / Mês / Ano.
class WideAgendaHeader extends StatelessWidget {
  final String title;
  final bool isLoading;
  final WideAgendaView view;
  final VoidCallback onToday;
  final ValueChanged<int> onMove;
  final ValueChanged<WideAgendaView> onViewChanged;

  const WideAgendaHeader({
    super.key,
    required this.title,
    required this.isLoading,
    required this.view,
    required this.onToday,
    required this.onMove,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: onToday,
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
          onPressed: () => onMove(-1),
          icon: const Icon(Icons.chevron_left, color: WideAgendaColors.text),
        ),
        IconButton(
          tooltip: 'Próximo',
          onPressed: () => onMove(1),
          icon: const Icon(Icons.chevron_right, color: WideAgendaColors.text),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: WideAgendaColors.text,
            ),
          ),
        ),
        if (isLoading) ...[
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
            ButtonSegment(value: WideAgendaView.day, label: Text('Dia')),
            ButtonSegment(value: WideAgendaView.week, label: Text('Semana')),
            ButtonSegment(value: WideAgendaView.month, label: Text('Mês')),
            ButtonSegment(value: WideAgendaView.year, label: Text('Ano')),
          ],
          selected: {view},
          onSelectionChanged: (s) => onViewChanged(s.first),
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
