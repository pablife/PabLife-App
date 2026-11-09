import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_schedule_slot.dart';
import '../../shared/themes/app_palette.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../shared/utils/brazil_holidays.dart';
import '../../widgets/design_system/app_dialog.dart';
import '../calendar/controllers/professional_wide_calendar_controller.dart';
import '../calendar/widgets/wide_agenda_views.dart';
import 'agenda_service.dart';
import 'professional_dashboard_page.dart' show firstNameAndInitial, hhmm;
import 'professional_room_page.dart';

/// Agenda do profissional no computador, no desenho do canvas (PAgenda):
/// coluna com Criar horário, Semana padrão e Legenda; à direita a semana
/// em grade de horas, com blocos livres, avulsos, consultas e bloqueados.
class ProfessionalWideAgendaPage extends StatefulWidget {
  const ProfessionalWideAgendaPage({super.key});

  @override
  State<ProfessionalWideAgendaPage> createState() =>
      _ProfessionalWideAgendaPageState();
}

class _ProfessionalWideAgendaPageState
    extends State<ProfessionalWideAgendaPage> {
  static const _wd = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
  static const _wdShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
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
  int _createDay = 0;
  int _createHour = 10;
  bool _adding = false;
  WeekPattern _pattern = {};
  int? _savingDay;

  ProfessionalWideCalendarController get _c =>
      Get.find<ProfessionalWideCalendarController>();

  @override
  void initState() {
    super.initState();
    if (_c.view == WideAgendaView.month || _c.view == WideAgendaView.year) {
      // Mantém a escolha da pessoa.
    } else if (_c.view != WideAgendaView.week &&
        _c.view != WideAgendaView.day) {
      _c.setView(WideAgendaView.week);
    }
    _createDay = DateTime.now().weekday % 7;
    _loadPattern();
  }

  Future<void> _loadPattern() async {
    for (var i = 0; i < 20 && _c.professionalId == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    final id = _c.professionalId;
    if (id == null) return;
    final p = await _c.agenda.weekPattern(id);
    if (mounted) setState(() => _pattern = p);
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _title(ProfessionalWideCalendarController c) {
    final days = c.weekDays;
    final a = days.first;
    final b = days.last;
    if (c.view == WideAgendaView.month || c.view == WideAgendaView.year) {
      return c.title;
    }
    if (days.length == 1) {
      return '${a.day} de ${_months[a.month - 1]} de ${a.year}';
    }
    if (a.month == b.month) {
      return '${a.day} a ${b.day} de ${_months[b.month - 1]} de ${b.year}';
    }
    return '${a.day} de ${_months[a.month - 1]} a ${b.day} de '
        '${_months[b.month - 1]} de ${b.year}';
  }

  /// "08:00–12:00 · 14:00–18:00" a partir dos horários da semana padrão.
  static String _ranges(Iterable<String> times) {
    final starts = times.map((t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }).toList()..sort();
    if (starts.isEmpty) return 'Folga';
    final parts = <String>[];
    var from = starts.first;
    var prev = starts.first;
    for (final s in starts.skip(1)) {
      if (s - prev > 60) {
        parts.add('${_fmt(from)}–${_fmt(prev + 60)}');
        from = s;
      }
      prev = s;
    }
    parts.add('${_fmt(from)}–${_fmt(prev + 60)}');
    return parts.join(' · ');
  }

  static String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _toggleDay(int weekday, bool on) async {
    final id = _c.professionalId;
    if (id == null) return;
    final desired = {
      for (final e in _pattern.entries) e.key: e.value.keys.toSet(),
    };
    if (on) {
      desired[weekday] = {
        ...?desired[weekday],
        ...WeekPeriod.morning.hours.map((h) => AgendaService.hhmm(h)),
        ...WeekPeriod.afternoon.hours.map((h) => AgendaService.hhmm(h)),
      };
    } else {
      final count = _pattern[weekday]?.length ?? 0;
      final ok = await AppDialog.showConfirmation(
        context: context,
        title: 'Folga às ${_wdShort[weekday].toLowerCase()}s?',
        message:
            'Os $count horários que repetem neste dia deixam de abrir a partir '
            'de agora. Consultas já marcadas continuam valendo.',
        confirmText: 'Confirmar folga',
        cancelText: 'Voltar',
        icon: Icons.event_busy_rounded,
      );
      if (ok != true) return;
      desired[weekday] = {};
    }
    setState(() => _savingDay = weekday);
    final errors = await _c.agenda.saveWeekPattern(
      professionalId: id,
      current: _pattern,
      desired: desired,
    );
    if (errors.isNotEmpty) AppSnackbar.to.show(errors.first);
    await _loadPattern();
    await _c.load();
    if (mounted) setState(() => _savingDay = null);
  }

  Future<void> _add() async {
    final c = _c;
    final day =
        c.weekDays.firstWhereOrNull((d) => d.weekday % 7 == _createDay) ??
        c.weekDays.first;
    final at = DateTime(day.year, day.month, day.day, _createHour);
    if (at.isBefore(DateTime.now())) {
      AppSnackbar.to.show('Escolha um dia e horário que ainda não passou.');
      return;
    }
    setState(() => _adding = true);
    final ok = await c.addSlot(at, everyWeek: false);
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
        final freeWeek = days.fold<int>(0, (n, d) => n + c.freeCountOn(d));
        return Scaffold(
          backgroundColor: PabColors.background,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agenda',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        Text(
                          'Atendimentos online de 50 min. Os pacientes só '
                          'veem o que estiver livre.',
                          style: TextStyle(
                            fontSize: 14,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: PabColors.soft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$freeWeek horários livres na semana',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PabColors.softText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 290, child: _aside(c)),
                  const SizedBox(width: 20),
                  Expanded(child: _calendar(c)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ coluna

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PabColors.card,
      border: Border.all(color: PabColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );

  Widget _chipButton({
    required bool on,
    required VoidCallback onTap,
    required Widget child,
    double height = 40,
  }) => Material(
    color: on ? PabColors.ink : PabColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: on ? PabColors.ink : PabColors.line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: on ? Colors.white : PabColors.ink),
            child: child,
          ),
        ),
      ),
    ),
  );

  Widget _aside(ProfessionalWideCalendarController c) {
    final week = c.weekDays.length == 7
        ? c.weekDays
        : List.generate(
            7,
            (i) => ProfessionalWideCalendarController.weekStart(
              c.focusDate,
            ).add(Duration(days: i)),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => setState(() => _creating = !_creating),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: PabColors.accent,
            foregroundColor: PabColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Criar horário',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (_creating) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PabColors.card,
              border: Border.all(color: PabColors.accent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Novo horário · 50 min, online',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Dia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PabColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in week)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _chipButton(
                            on: d.weekday % 7 == _createDay,
                            height: 46,
                            onTap: () =>
                                setState(() => _createDay = d.weekday % 7),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _wd[d.weekday % 7],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${d.day}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Início',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PabColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.7,
                  children: [
                    for (var h = 7; h <= 18; h++)
                      _chipButton(
                        on: h == _createHour,
                        onTap: () => setState(() => _createHour = h),
                        child: Text(
                          AgendaService.hhmm(h),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _creating = false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: PabColors.ink,
                          side: const BorderSide(color: PabColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _adding ? null : _add,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: PabColors.ink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _adding ? 'Adicionando…' : 'Adicionar',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semana padrão',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    'repete toda semana',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PabColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final wd in const [1, 2, 3, 4, 5, 6, 0]) _weekRow(wd),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legenda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              _legend(
                const BoxDecoration(color: PabColors.soft),
                'Livre · toque para bloquear',
                dashed: true,
              ),
              _legend(
                const BoxDecoration(color: PabColors.accent),
                'Criado por você (avulso)',
              ),
              _legend(
                const BoxDecoration(color: PabColors.ink),
                'Consulta marcada',
              ),
              _legend(_striped, 'Bloqueado · toque para liberar'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClearAllSlotsButton(controller: c),
      ],
    );
  }

  static final _striped = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment(-0.85, -0.85),
      colors: [
        Color(0xFFECEFEF),
        Color(0xFFECEFEF),
        Colors.white,
        Colors.white,
      ],
      stops: [0, 0.5, 0.5, 1],
      tileMode: TileMode.repeated,
    ),
    border: Border.all(color: const Color(0xFFD5DCDC)),
  );

  Widget _legend(BoxDecoration deco, String label, {bool dashed = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: deco.copyWith(
                borderRadius: BorderRadius.circular(5),
                border: dashed
                    ? Border.all(color: PabColors.accentText, width: 1.5)
                    : deco.border,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: PabColors.ink),
            ),
          ],
        ),
      );

  Widget _weekRow(int weekday) {
    final times = _pattern[weekday]?.keys ?? const <String>[];
    final on = times.isNotEmpty;
    final busy = _savingDay == weekday;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          busy
              ? const SizedBox(
                  width: 40,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PabColors.accent,
                      ),
                    ),
                  ),
                )
              : Semantics(
                  toggled: on,
                  label: 'Atender ${_wdShort[weekday]}',
                  child: GestureDetector(
                    onTap: _savingDay != null
                        ? null
                        : () => _toggleDay(weekday, !on),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 24,
                      padding: const EdgeInsets.all(3),
                      alignment: on
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: on
                            ? PabColors.accentText
                            : const Color(0xFFCBD5D6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              _wdShort[weekday],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _ranges(times),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: on ? PabColors.ink : const Color(0xFF8A9899),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ calendário

  Widget _calendar(ProfessionalWideCalendarController c) {
    Widget square(IconData icon, String tip, VoidCallback onTap) => Tooltip(
      message: tip,
      child: Material(
        color: PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: PabColors.ink),
          ),
        ),
      ),
    );

    final body = switch (c.view) {
      WideAgendaView.month => SizedBox(
        height: 640,
        child: WideMonthView(controller: c),
      ),
      WideAgendaView.year => SizedBox(
        height: 640,
        child: WideYearView(controller: c),
      ),
      _ => _weekGrid(c),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: c.goToday,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: PabColors.ink,
                  side: const BorderSide(color: PabColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hoje',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              square(Icons.chevron_left_rounded, 'Anterior', () => c.move(-1)),
              const SizedBox(width: 6),
              square(Icons.chevron_right_rounded, 'Próximo', () => c.move(1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title(c),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              if (c.isLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PabColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PabColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (final (v, label) in const [
                      (WideAgendaView.day, 'Dia'),
                      (WideAgendaView.week, 'Semana'),
                      (WideAgendaView.month, 'Mês'),
                      (WideAgendaView.year, 'Ano'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Material(
                          color: c.view == v
                              ? PabColors.ink
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => c.setView(v),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.view == v
                                      ? Colors.white
                                      : PabColors.ink,
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
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  static const _hourHeight = 48.0;
  static const _gutter = 56.0;
  static const _grid = Color(0xFFE4ECEC);
  static const _gridSoft = Color(0xFFEDF2F2);

  Widget _weekGrid(ProfessionalWideCalendarController c) {
    final days = c.weekDays;
    final now = DateTime.now();
    final holidaysByYear = <int, Map<DateTime, String>>{};
    String? holiday(DateTime d) => (holidaysByYear[d.year] ??= brazilHolidays(
      d.year,
    ))[DateTime(d.year, d.month, d.day)];

    // Faixa de horas: 07:00–19:00, ou mais se houver algo fora.
    var first = 7;
    var last = 19;
    for (final d in days) {
      for (final s in c.slotsOn(d)) {
        final l = s.startAt.toLocal();
        first = math.min(first, l.hour);
        last = math.max(last, math.min(23, l.hour + 1));
      }
    }
    final hours = [for (var h = first; h <= last; h++) h];
    final gridHeight = hours.length * _hourHeight;
    double top(DateTime t) =>
        (t.hour + t.minute / 60 - first) * _hourHeight + 2;
    const blockHeight = 50 / 60 * _hourHeight - 4;

    return Column(
      children: [
        // Cabeçalho dos dias.
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _grid)),
          ),
          child: Row(
            children: [
              const SizedBox(width: _gutter),
              for (final d in days)
                Expanded(child: _dayHeader(c, d, holiday(d), now)),
            ],
          ),
        ),
        // Faixa "dia todo" (feriados).
        Container(
          constraints: const BoxConstraints(minHeight: 34),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _grid)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: _gutter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8, right: 6),
                    child: Text(
                      'dia todo',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: PabColors.muted),
                    ),
                  ),
                ),
                for (final d in days)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: _gridSoft)),
                      ),
                      child: holiday(d) == null
                          ? null
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCE8F3),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '${holiday(d)} · feriado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7A1F52),
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Grade das horas.
        SizedBox(
          height: gridHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _gutter,
                child: Column(
                  children: [
                    for (final h in hours)
                      SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Transform.translate(
                            offset: const Offset(0, -7),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                AgendaService.hhmm(h),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PabColors.muted,
                                ),
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
                    height: gridHeight,
                    decoration: BoxDecoration(
                      color: _same(d, now)
                          ? const AppColor.pair(0xFFF2FBFA, 0xFFFDF3F8)
                          : null,
                      border: const Border(left: BorderSide(color: _gridSoft)),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < hours.length; i++)
                          Positioned(
                            top: i * _hourHeight,
                            left: 0,
                            right: 0,
                            child: Container(height: 1, color: _grid),
                          ),
                        for (final s in c.slotsOn(d))
                          Positioned(
                            top: top(s.startAt.toLocal()),
                            left: 4,
                            right: 4,
                            height: blockHeight,
                            child: _block(c, s),
                          ),
                        for (final b in c.blockedOn(d))
                          Positioned(
                            top: top(b.startAt),
                            left: 4,
                            right: 4,
                            height: blockHeight,
                            child: _blockedBlock(c, b),
                          ),
                        if (_same(d, now) &&
                            now.hour >= first &&
                            now.hour <= last)
                          Positioned(
                            top:
                                (now.hour + now.minute / 60 - first) *
                                _hourHeight,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 2,
                                color: PabColors.pink,
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
      ],
    );
  }

  Widget _dayHeader(
    ProfessionalWideCalendarController c,
    DateTime d,
    String? holiday,
    DateTime now,
  ) {
    final isToday = _same(d, now);
    final booked = c.appointmentCountOn(d);
    final free = c.freeCountOn(d);
    final sum = holiday != null && booked + free == 0
        ? 'feriado'
        : booked + free == 0
        ? 'folga'
        : '$booked marc. · $free ${free == 1 ? 'livre' : 'livres'}';
    final quiet = booked + free == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Column(
        children: [
          Text(
            _wd[d.weekday % 7],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isToday ? PabColors.accentText : PabColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? PabColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${d.day}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sum,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: quiet ? const Color(0xFF8A9899) : PabColors.accentText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockShell({
    required BoxDecoration decoration,
    required Color fg,
    required String time,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Ink(
            decoration: decoration.copyWith(
              borderRadius: BorderRadius.circular(9),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _block(
    ProfessionalWideCalendarController c,
    ProfessionalScheduleSlot s,
  ) {
    final time = hhmm(s.startAt);
    final a = s.appointment;
    if (a != null) {
      return _blockShell(
        decoration: const BoxDecoration(color: PabColors.ink),
        fg: Colors.white,
        time: time,
        label: firstNameAndInitial(a.patientName),
        tooltip: 'Consulta com ${a.patientName} às $time',
        onTap: () => ProfessionalRoomPage.open(a),
      );
    }
    if (!s.isRecurring) {
      return _blockShell(
        decoration: const BoxDecoration(color: PabColors.accent),
        fg: PabColors.ink,
        time: time,
        label: 'Livre · avulso',
        tooltip: 'Horário avulso às $time — clique para remover',
        onTap: () => c.blockSlot(s),
      );
    }
    return _blockShell(
      decoration: BoxDecoration(
        color: PabColors.soft,
        border: Border.all(color: PabColors.accentText, width: 1.5),
      ),
      fg: PabColors.softText,
      time: time,
      label: 'Livre',
      tooltip: 'Bloquear $time',
      onTap: () => c.blockSlot(s),
    );
  }

  Widget _blockedBlock(ProfessionalWideCalendarController c, BlockedSlot b) {
    return _blockShell(
      decoration: _striped,
      fg: PabColors.muted,
      time: hhmm(b.startAt),
      label: 'Bloqueado',
      tooltip: 'Liberar ${hhmm(b.startAt)}',
      onTap: () => c.releaseBlocked(b),
    );
  }
}

/// "Apagar todos os horários" (com a pergunta antes), no computador e no
/// celular.
class ClearAllSlotsButton extends StatelessWidget {
  final ProfessionalWideCalendarController controller;

  const ClearAllSlotsButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: controller.isLoading
          ? null
          : () => controller.clearAllSlots(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: PabColors.card,
        foregroundColor: PabColors.error,
        side: const BorderSide(color: PabColors.errorLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      label: const Text(
        'Apagar todos os horários',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
