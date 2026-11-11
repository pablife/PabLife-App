import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

final _dayMonth = DateFormat("d 'de' MMMM", 'pt_BR');
final _monthYear = DateFormat("MMMM 'de' y", 'pt_BR');

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime get _today => _dateOnly(DateTime.now());

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Atalhos da Saúde da Mulher: Menstruação, Tentativas (Quero gestar) e
/// Testes. Ficam no cartão do ciclo do Dashboard.
class CycleToolsRow extends StatelessWidget {
  final WomenHealthController women;

  const CycleToolsRow({super.key, required this.women});

  @override
  Widget build(BuildContext context) {
    final trail = women.trail;
    if (trail == null || trail == WomenTrail.pregnancy) {
      return const SizedBox.shrink();
    }
    final items = [
      (Icons.water_drop_outlined, 'Menstruação', () => PeriodLogPage.open()),
      if (trail == WomenTrail.conceive)
        (
          Icons.favorite_border_rounded,
          'Tentativas',
          () => AttemptsPage.open(),
        ),
      if (trail != WomenTrail.menopause)
        (Icons.science_outlined, 'Testes', () => TestsPage.open()),
    ];
    return Row(
      children: [
        for (final (i, (icon, label, onTap)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Icon(icon, size: 22, color: PabColors.softText),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: PabColors.softText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Moldura das três telas: cabeçalho escuro com voltar, título e subtítulo.
class _ToolFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ToolFrame({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return PabCardFrame(
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: PabColors.ink,
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.paddingOf(context).top + 10,
              16,
              18,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: PabColors.onInk,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAÚDE DA MULHER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PabColors.onInkSoft,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: PabColors.onInk,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PabColors.onInkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GetBuilder<WomenHealthController>(
              builder: (_) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _card(Widget child, {Color? color}) => Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: color ?? PabColors.card,
    border: color == null ? Border.all(color: PabColors.line) : null,
    borderRadius: BorderRadius.circular(20),
  ),
  child: child,
);

Widget _sectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: PabColors.muted,
    ),
  ),
);

Widget _note(String text) => Container(
  padding: const EdgeInsets.all(12),
  margin: const EdgeInsets.only(top: 10),
  decoration: BoxDecoration(
    color: PabColors.lilac,
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      height: 1.5,
      color: PabColors.lilacText,
    ),
  ),
);

Future<DateTime?> _pickPastDay(BuildContext context, {DateTime? initial}) {
  return showDatePicker(
    context: context,
    initialDate: initial ?? _today,
    firstDate: DateTime(_today.year - 2),
    lastDate: _today,
    locale: const Locale('pt', 'BR'),
    helpText: 'Escolha o dia',
  );
}

// ------------------------------------------------------------- menstruação

/// "Minha menstruação": registra quando veio, quando terminou e quando não
/// veio. Com os registros, o ciclo médio e a previsão ficam mais certos.
class PeriodLogPage extends StatelessWidget {
  const PeriodLogPage({super.key});

  static Future<void> open() => Get.to<void>(() => const PeriodLogPage())!;

  @override
  Widget build(BuildContext context) {
    final w = WomenHealthController.to;
    return _ToolFrame(
      title: 'Minha menstruação',
      subtitle: 'Registre quando vem, quando termina e quando atrasa.',
      children: [_PeriodBody(women: w)],
    );
  }
}

class _PeriodBody extends StatelessWidget {
  final WomenHealthController women;

  const _PeriodBody({required this.women});

  @override
  Widget build(BuildContext context) {
    final w = women;
    final last = w.lastPeriod;
    final today = _today;
    final cycleDay = last == null ? null : today.difference(last).inDays + 1;
    final late = w.daysLate;
    final avg = w.averageCycle;
    final history = w.cycleHistory;
    final noPeriods = w.logsOf(WomenLog.noPeriod);
    final startedToday = w.logOn(today, WomenLog.periodStart) != null;
    final endedToday = w.logOn(today, WomenLog.periodEnd) != null;
    final next = last?.add(Duration(days: w.cycleLength));

    final status = last == null
        ? 'Sem registro ainda'
        : startedToday
        ? 'Menstruação de hoje registrada'
        : late > 0
        ? 'Atrasada há $late ${late == 1 ? 'dia' : 'dias'}'
        : 'Dia $cycleDay do ciclo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              const SizedBox(height: 6),
              if (last != null)
                Text(
                  'Última: ${_dayMonth.format(last)}'
                  '${next == null ? '' : ' · próxima prevista: ${_dayMonth.format(next)}'}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: PabColors.onInkSoft,
                  ),
                ),
              Text(
                avg == null
                    ? 'Ciclo de ${w.cycleLength} dias (informado por você). '
                          'Com dois registros, calculamos o seu.'
                    : 'Seu ciclo médio: $avg dias, pelos seus registros.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: PabColors.onInkSoft,
                ),
              ),
            ],
          ),
          color: PabColors.ink,
        ),
        RegPrimaryButton(
          label: startedToday
              ? 'Veio hoje · registrado'
              : 'Minha menstruação veio hoje',
          icon: const Icon(
            Icons.water_drop_rounded,
            size: 20,
            color: PabColors.ink,
          ),
          onTap: startedToday ? null : () => w.registerPeriodStart(today),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _outlined(
                'Veio em outro dia',
                Icons.event_rounded,
                () async {
                  final day = await _pickPastDay(context);
                  if (day != null) await w.registerPeriodStart(day);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _outlined(
                endedToday ? 'Terminou · registrado' : 'Terminou hoje',
                Icons.check_circle_outline_rounded,
                endedToday ? null : () => w.registerPeriodEnd(today),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _outlined(
          w.markedNoPeriod ? 'Não veio · registrado' : 'Não veio este mês',
          Icons.event_busy_rounded,
          w.markedNoPeriod
              ? null
              : () async {
                  final ok = await AppDialog.showConfirmation(
                    context: context,
                    title: 'A menstruação não veio?',
                    message:
                        'Vamos registrar que ela não veio neste mês. Isso '
                        'ajuda a acompanhar atrasos e ciclos irregulares.',
                    confirmText: 'Registrar',
                    cancelText: 'Voltar',
                    icon: Icons.event_busy_rounded,
                  );
                  if (ok == true) await w.registerNoPeriod();
                },
        ),
        if (late > 0 || w.markedNoPeriod)
          _note(
            'Atrasos acontecem por estresse, mudança de rotina, alimentação, '
            'sono ou outras causas. Se existe chance de gravidez, faça um '
            'teste. Se a menstruação continuar sem vir, procure a sua '
            'ginecologista.',
          ),
        if ((late > 0 || w.markedNoPeriod) && w.trail != WomenTrail.menopause)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _outlined(
              'Registrar teste de gravidez',
              Icons.science_outlined,
              () => TestsPage.open(),
            ),
          ),
        const SizedBox(height: 18),
        _sectionTitle('HISTÓRICO'),
        if (history.isEmpty && noPeriods.isEmpty)
          const Text(
            'Seus registros aparecem aqui.',
            style: TextStyle(fontSize: 13, color: PabColors.muted),
          ),
        for (final c in history)
          _historyRow(
            context,
            title: 'Começou em ${_dayMonth.format(c.start)}',
            detail: [
              if (c.periodDays != null) 'durou ${c.periodDays} dias',
              if (c.length != null) 'ciclo de ${c.length} dias',
            ].join(' · '),
            onDelete: () async {
              final ok = await AppDialog.showConfirmation(
                context: context,
                title: 'Apagar este registro?',
                message:
                    'O começo da menstruação de ${_dayMonth.format(c.start)} '
                    'sai do histórico e o ciclo é recalculado.',
                confirmText: 'Apagar',
                cancelText: 'Voltar',
                destructive: true,
              );
              if (ok == true) {
                await w.removeLog(c.start, WomenLog.periodStart);
                if (c.periodEnd != null) {
                  await w.removeLog(c.periodEnd!, WomenLog.periodEnd);
                }
              }
            },
          ),
        for (final n in noPeriods)
          _historyRow(
            context,
            title: 'Não veio · ${_cap(_monthYear.format(n.day))}',
            detail: 'registrado em ${_dayMonth.format(n.day)}',
            onDelete: () => w.removeLog(n.day, WomenLog.noPeriod),
          ),
      ],
    );
  }

  Widget _outlined(String label, IconData icon, VoidCallback? onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: PabColors.card,
          foregroundColor: PabColors.ink,
          disabledForegroundColor: PabColors.muted,
          side: const BorderSide(color: PabColors.lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );

  Widget _historyRow(
    BuildContext context, {
    required String title,
    required String detail,
    required VoidCallback onDelete,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
    decoration: BoxDecoration(
      color: PabColors.card,
      border: Border.all(color: PabColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.water_drop_rounded,
          size: 18,
          color: PabColors.menstruation,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: PabColors.muted),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Apagar',
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: PabColors.muted,
            size: 20,
          ),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- tentativas

/// "Dias de tentativa" (Quero gestar): o mês com o período fértil previsto e
/// a ovulação; tocar num dia marca ou desmarca a tentativa.
class AttemptsPage extends StatefulWidget {
  const AttemptsPage({super.key});

  static Future<void> open() => Get.to<void>(() => const AttemptsPage())!;

  @override
  State<AttemptsPage> createState() => _AttemptsPageState();
}

class _AttemptsPageState extends State<AttemptsPage> {
  late DateTime _month = DateTime(_today.year, _today.month);

  @override
  Widget build(BuildContext context) {
    final w = WomenHealthController.to;
    return _ToolFrame(
      title: 'Dias de tentativa',
      subtitle: 'Marque os dias e veja o período fértil previsto.',
      children: [_body(w)],
    );
  }

  Widget _body(WomenHealthController w) {
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday % 7;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final last = w.lastPeriod;
    final cycleStart = last?.add(
      Duration(
        days: (_today.difference(last).inDays ~/ w.cycleLength) * w.cycleLength,
      ),
    );
    final attemptsThisCycle = cycleStart == null
        ? 0
        : w
              .logsOf(WomenLog.attempt)
              .where((l) => !l.day.isBefore(cycleStart))
              .length;
    final inFertile = cycleStart == null
        ? 0
        : w
              .logsOf(WomenLog.attempt)
              .where(
                (l) =>
                    !l.day.isBefore(cycleStart) &&
                    w.cyclePhaseOn(l.day)?.kind == WomenCycleKind.fertile,
              )
              .length;

    Widget cell(int n) {
      final day = DateTime(_month.year, _month.month, n);
      final phase = w.cyclePhaseOn(day);
      final fertile = phase?.kind == WomenCycleKind.fertile;
      final ovulation = phase?.label == 'Previsão de ovulação';
      final period = phase?.kind == WomenCycleKind.menstruation;
      final attempt = w.logOn(day, WomenLog.attempt) != null;
      final isToday = day == _today;
      final future = day.isAfter(_today);
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: ovulation
              ? PabColors.fertile.withValues(alpha: 0.35)
              : fertile
              ? const Color(0xFFEEEDFF)
              : period
              ? const Color(0xFFFCE8F3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isToday ? PabColors.ink : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: future ? null : () => w.toggleAttempt(day),
            child: SizedBox(
              height: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: future
                          ? PabColors.ink.withValues(alpha: 0.55)
                          : PabColors.ink,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: attempt
                        ? const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: PabColors.menstruation,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$attemptsThisCycle '
                '${attemptsThisCycle == 1 ? 'tentativa' : 'tentativas'} neste ciclo',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$inFertile no período fértil previsto',
                style: const TextStyle(
                  fontSize: 13,
                  color: PabColors.onInkSoft,
                ),
              ),
            ],
          ),
          color: PabColors.ink,
        ),
        _card(
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _cap(_monthYear.format(_month)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final l in const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
                    Expanded(
                      child: Text(
                        l,
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
              const SizedBox(height: 4),
              for (var r = 0; r < rows; r++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: () {
                          final n = r * 7 + col - leading + 1;
                          if (n < 1 || n > daysInMonth) {
                            return const SizedBox(height: 56);
                          }
                          return cell(n);
                        }(),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _legend(const Color(0xFFFCE8F3), 'Menstruação'),
                  _legend(const Color(0xFFEEEDFF), 'Fértil (previsto)'),
                  _legend(
                    PabColors.fertile.withValues(alpha: 0.35),
                    'Ovulação prevista',
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: PabColors.menstruation,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Tentativa',
                        style: TextStyle(fontSize: 12, color: PabColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        _note(
          'As melhores chances costumam ser nos 2 a 3 dias antes da ovulação '
          'e no próprio dia. As datas são previsões pelo seu ciclo e podem '
          'variar: o teste de ovulação ajuda a confirmar. Toque num dia para '
          'marcar ou desmarcar a tentativa.',
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: PabColors.muted)),
    ],
  );
}

// ------------------------------------------------------------------ testes

/// "Testes" (como no Flo): teste de ovulação e teste de gravidez do dia.
class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  static Future<void> open() => Get.to<void>(() => const TestsPage())!;

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  DateTime _day = _today;

  static const _ovulation = [
    ('positive', 'Positivo', 'Teste de ovulação'),
    ('negative', 'Negativo', 'Teste de ovulação'),
    ('not_done', 'Não fiz os testes', null),
    ('own_method', 'Ovulação: meu método', null),
  ];

  static const _pregnancy = [
    ('not_done', 'Não fiz testes'),
    ('positive', 'Positivo'),
    ('negative', 'Negativo'),
    ('faint_line', 'Linha fraca'),
  ];

  static String _label(String kind, String? value) {
    if (kind == WomenLog.ovulationTest) {
      return switch (value) {
        'positive' => 'Ovulação: positivo',
        'negative' => 'Ovulação: negativo',
        'own_method' => 'Ovulação pelo meu método',
        _ => 'Ovulação: não fiz o teste',
      };
    }
    return switch (value) {
      'positive' => 'Gravidez: positivo',
      'negative' => 'Gravidez: negativo',
      'faint_line' => 'Gravidez: linha fraca',
      _ => 'Gravidez: não fiz o teste',
    };
  }

  @override
  Widget build(BuildContext context) {
    final w = WomenHealthController.to;
    return _ToolFrame(
      title: 'Testes',
      subtitle: 'Registre os testes de ovulação e de gravidez.',
      children: [_body(context, w)],
    );
  }

  Widget _option(String label, bool on, VoidCallback onTap) => Material(
    color: on ? PabColors.ink : PabColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: on ? PabColors.ink : PabColors.lineStrong),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : PabColors.ink,
          ),
        ),
      ),
    ),
  );

  /// Opções em duas colunas; a altura acompanha o texto.
  Widget _grid(List<Widget> items) => Column(
    children: [
      for (var i = 0; i < items.length; i += 2)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: items[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < items.length ? items[i + 1] : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _body(BuildContext context, WomenHealthController w) {
    final ovulation = w.logOn(_day, WomenLog.ovulationTest)?.value;
    final pregnancy = w.logOn(_day, WomenLog.pregnancyTest)?.value;
    final recent = [
      ...w.logsOf(WomenLog.ovulationTest),
      ...w.logsOf(WomenLog.pregnancyTest),
    ]..sort((a, b) => b.day.compareTo(a.day));

    final days = [
      for (var i = 0; i < 7; i++) _today.subtract(Duration(days: i)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('DIA DO TESTE'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      d == _today
                          ? 'Hoje'
                          : DateFormat('E d', 'pt_BR').format(d),
                    ),
                    selected: d == _day,
                    onSelected: (_) => setState(() => _day = d),
                    showCheckmark: false,
                    selectedColor: PabColors.ink,
                    backgroundColor: PabColors.card,
                    side: BorderSide(
                      color: d == _day ? PabColors.ink : PabColors.line,
                    ),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: d == _day ? Colors.white : PabColors.ink,
                    ),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.event_rounded, size: 16),
                label: const Text('Outro dia'),
                onPressed: () async {
                  final d = await _pickPastDay(context, initial: _day);
                  if (d != null) setState(() => _day = _dateOnly(d));
                },
                backgroundColor: PabColors.card,
                side: const BorderSide(color: PabColors.line),
                shape: const StadiumBorder(),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (w.trail != WomenTrail.menopause)
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('TESTES DE OVULAÇÃO'),
                const Text(
                  'Registre seu teste de ovulação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _grid([
                  for (final (value, label, _) in _ovulation)
                    _option(
                      label,
                      ovulation == value,
                      () => w.setTest(_day, WomenLog.ovulationTest, value),
                    ),
                ]),
                if (ovulation == 'positive')
                  _note(
                    'Teste positivo: o pico do hormônio LH costuma vir 24 a '
                    '36 horas antes da ovulação. Estes são os melhores dias '
                    'para tentar.',
                  ),
                if (ovulation == 'own_method')
                  _note(
                    'Ovulação registrada pelo seu método (muco, temperatura '
                    'ou sinais do corpo).',
                  ),
              ],
            ),
          ),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('TESTES DE GRAVIDEZ'),
              _grid([
                for (final (value, label) in _pregnancy)
                  _option(
                    label,
                    pregnancy == value,
                    () => w.setTest(_day, WomenLog.pregnancyTest, value),
                  ),
              ]),
              if (pregnancy == 'positive')
                _note(
                  'Que notícia! Confirme com o exame de sangue (beta-hCG) e '
                  'marque uma consulta com a sua ginecologista. Quando quiser, '
                  'mude a sua trilha para Gestação no Perfil.',
                ),
              if (pregnancy == 'faint_line')
                _note(
                  'Linha fraca pode indicar o começo de uma gravidez ou um '
                  'teste feito cedo demais. Repita em 48 horas, de '
                  'preferência com a primeira urina da manhã.',
                ),
              if (pregnancy == 'negative')
                _note(
                  'Se a menstruação não vier, repita o teste em alguns dias.',
                ),
            ],
          ),
        ),
        _sectionTitle('ÚLTIMOS REGISTROS'),
        if (recent.isEmpty)
          const Text(
            'Seus testes aparecem aqui.',
            style: TextStyle(fontSize: 13, color: PabColors.muted),
          ),
        for (final l in recent.take(20))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PabColors.card,
              border: Border.all(color: PabColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  l.kind == WomenLog.ovulationTest
                      ? Icons.egg_outlined
                      : Icons.child_friendly_outlined,
                  size: 18,
                  color: PabColors.softText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(l.kind, l.value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                ),
                Text(
                  _dayMonth.format(l.day),
                  style: const TextStyle(fontSize: 12, color: PabColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
