import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_schedule_slot.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/brazil_holidays.dart';
import '../../widgets/pab_logo.dart';
import '../calendar/controllers/professional_wide_calendar_controller.dart';
import 'agenda_service.dart';
import 'professional_dashboard_page.dart' show firstNameAndInitial, hhmm;
import 'professional_room_page.dart';
import 'week_pattern_sheet.dart';

/// Agenda do profissional no celular (canvas PA): faixa da semana, Semana
/// padrão, Criar horário e os horários do dia (tocar bloqueia ou libera).
class ProfessionalAgendaPage extends StatefulWidget {
  const ProfessionalAgendaPage({super.key});

  @override
  State<ProfessionalAgendaPage> createState() => _ProfessionalAgendaPageState();
}

class _ProfessionalAgendaPageState extends State<ProfessionalAgendaPage> {
  static const _wd = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
  static const _wdName = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];
  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  bool _creating = false;
  int _createHour = 18;
  bool _everyWeek = false;
  bool _adding = false;

  ProfessionalWideCalendarController get _c =>
      Get.find<ProfessionalWideCalendarController>();

  @override
  void initState() {
    super.initState();
    final c = _c;
    if (c.view != WideAgendaView.week) {
      c.setView(WideAgendaView.week);
    }
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openPattern() async {
    final id = _c.professionalId;
    if (id == null) return;
    final changed = await WeekPatternSheet.open(
      context,
      professionalId: id,
      service: _c.agenda,
    );
    if (changed) await _c.load();
  }

  Future<void> _add(DateTime day) async {
    setState(() => _adding = true);
    final ok = await _c.addSlot(
      DateTime(day.year, day.month, day.day, _createHour),
      everyWeek: _everyWeek,
    );
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (ok) _creating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalWideCalendarController>(
      builder: (c) {
        final days = c.weekDays;
        final selected = days.any((d) => _same(d, c.selectedDay))
            ? c.selectedDay
            : days.first;
        final all = c.slotsOn(selected);
        final booked = all.where((s) => s.hasAppointment).toList();
        final free = all.where((s) => !s.hasAppointment).toList();
        final blocked = c.blockedOn(selected);
        final freeWeek = days.fold<int>(0, (n, d) => n + c.freeCountOn(d));
        final holiday = brazilHolidays(
          selected.year,
        )[DateTime(selected.year, selected.month, selected.day)];
        final monthLabel =
            '${_months[days.first.month - 1][0].toUpperCase()}'
            '${_months[days.first.month - 1].substring(1)} de ${days.first.year}';

        return Scaffold(
          backgroundColor: PabColors.background,
          body: RefreshIndicator(
            color: PabColors.accent,
            onRefresh: c.load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(context, c, days, selected, monthLabel, freeWeek),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () => setState(() => _creating = !_creating),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: PabColors.accent,
                          foregroundColor: PabColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Criar horário',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_creating) ...[
                        const SizedBox(height: 10),
                        _createPanel(selected, all),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '${_wdName[selected.weekday % 7]}, '
                              '${selected.day} de ${_months[selected.month - 1]}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: PabColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${booked.length} '
                            '${booked.length == 1 ? 'marcada' : 'marcadas'} · '
                            '${free.length} '
                            '${free.length == 1 ? 'livre' : 'livres'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: PabColors.accentText,
                            ),
                          ),
                        ],
                      ),
                      if (holiday != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Feriado: $holiday',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B4A00),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (c.isLoading && all.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: PabColors.accent,
                            ),
                          ),
                        )
                      else if (all.isEmpty && blocked.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: PabColors.card,
                            border: Border.all(color: PabColors.line),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'Dia sem horários',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: PabColors.ink,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ligue este dia na Semana padrão ou use '
                                'Criar horário.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: PabColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final s in booked) ...[
                        _bookedCard(s),
                        const SizedBox(height: 8),
                      ],
                      if (free.isNotEmpty || blocked.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Toque num horário para bloquear ou liberar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: PabColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _slotGrid(c, free, blocked),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    ProfessionalWideCalendarController c,
    List<DateTime> days,
    DateTime selected,
    String monthLabel,
    int freeWeek,
  ) {
    final today = DateTime.now();
    return Container(
      color: PabColors.ink,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 18,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PabLogo(size: 22),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agenda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PabColors.onInk,
                      ),
                    ),
                    Text(
                      '$monthLabel · $freeWeek '
                      '${freeWeek == 1 ? 'livre' : 'livres'} na semana',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PabColors.onInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openPattern,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: PabColors.onInk,
                  backgroundColor: PabColors.onInk.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: PabColors.onInk.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text(
                  'Semana padrão',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _arrow(Icons.chevron_left_rounded, () => c.move(-1)),
              for (final d in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: _same(d, selected)
                          ? PabColors.accent
                          : PabColors.onInk.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => c.selectDay(d),
                        child: SizedBox(
                          height: 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _wd[d.weekday % 7],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _same(d, selected)
                                      ? PabColors.ink
                                      : PabColors.onInk,
                                ),
                              ),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: _same(d, today)
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                  decoration: _same(d, today)
                                      ? TextDecoration.underline
                                      : null,
                                  decorationColor: _same(d, selected)
                                      ? PabColors.ink
                                      : PabColors.onInk,
                                  color: _same(d, selected)
                                      ? PabColors.ink
                                      : PabColors.onInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.freeCountOn(d) > 0
                                      ? (_same(d, selected)
                                            ? PabColors.ink
                                            : PabColors.accent)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              _arrow(Icons.chevron_right_rounded, () => c.move(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => SizedBox(
    width: 28,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, color: PabColors.onInk),
    ),
  );

  Widget _createPanel(DateTime day, List<ProfessionalScheduleSlot> existing) {
    final taken = existing.map((s) => s.startAt.toLocal().hour).toSet();
    final now = DateTime.now();
    final hours = [for (var h = 7; h <= 21; h++) h]
        .where((h) => !taken.contains(h))
        .where((h) => DateTime(day.year, day.month, day.day, h).isAfter(now))
        .toList();
    if (!hours.contains(_createHour) && hours.isNotEmpty) {
      _createHour = hours.first;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.accent, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Novo horário · ${_wdName[day.weekday % 7].toLowerCase()}, '
            '${day.day}/${day.month} · 50 min',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (hours.isEmpty)
            const Text(
              'Não há horário livre para criar neste dia.',
              style: TextStyle(fontSize: 13, color: PabColors.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in hours)
                  ChoiceChip(
                    label: Text(AgendaService.hhmm(h)),
                    selected: h == _createHour,
                    onSelected: (_) => setState(() => _createHour = h),
                    showCheckmark: false,
                    selectedColor: PabColors.ink,
                    backgroundColor: PabColors.card,
                    side: BorderSide(
                      color: h == _createHour ? PabColors.ink : PabColors.line,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: h == _createHour ? Colors.white : PabColors.ink,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _everyWeek,
            onChanged: (v) => setState(() => _everyWeek = v),
            activeTrackColor: PabColors.accent,
            title: const Text(
              'Repetir toda semana',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PabColors.ink,
              ),
            ),
          ),
          FilledButton(
            onPressed: hours.isEmpty || _adding ? null : () => _add(day),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: PabColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _adding ? 'Adicionando…' : 'Adicionar horário',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookedCard(ProfessionalScheduleSlot s) {
    final a = s.appointment!;
    return Material(
      color: PabColors.ink,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ProfessionalRoomPage.open(a),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  hhmm(s.startAt),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstNameAndInitial(a.patientName),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Consulta · 50 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: PabColors.onInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: PabColors.onInk),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotGrid(
    ProfessionalWideCalendarController c,
    List<ProfessionalScheduleSlot> free,
    List<BlockedSlot> blocked,
  ) {
    final items = <(DateTime, Widget)>[
      for (final s in free) (s.startAt.toLocal(), _freeTile(c, s)),
      for (final b in blocked) (b.startAt, _blockedTile(c, b)),
    ]..sort((x, y) => x.$1.compareTo(y.$1));
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.1,
      children: [for (final (_, w) in items) w],
    );
  }

  Widget _freeTile(
    ProfessionalWideCalendarController c,
    ProfessionalScheduleSlot s,
  ) {
    final single = !s.isRecurring;
    return Tooltip(
      message: 'Bloquear ${hhmm(s.startAt)}',
      child: Material(
        color: single ? PabColors.lilac : PabColors.soft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: single ? PabColors.lilacText : PabColors.accentText,
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => c.blockSlot(s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hhmm(s.startAt),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: single ? PabColors.lilacText : PabColors.softText,
                ),
              ),
              Text(
                single ? 'Livre · avulso' : 'Livre',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: single ? PabColors.lilacText : PabColors.softText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockedTile(ProfessionalWideCalendarController c, BlockedSlot b) {
    return Tooltip(
      message: 'Liberar ${hhmm(b.startAt)}',
      child: Material(
        color: PabColors.track,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFD5DCDC)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => c.releaseBlocked(b),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hhmm(b.startAt),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7D8C8D),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Text(
                'Bloqueado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7D8C8D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
