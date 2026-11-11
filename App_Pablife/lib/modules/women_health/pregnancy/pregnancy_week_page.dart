import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import 'pregnancy_controller.dart';
import 'pregnancy_models.dart';
import 'pregnancy_record_page.dart';
import 'pregnancy_widgets.dart';

/// Uma semana da gestação: ilustração, medidas, o bebê, o corpo, o que
/// conversar com a médica e os sinais de alerta.
class PregnancyWeekPage extends StatefulWidget {
  final int initialWeek;

  const PregnancyWeekPage({super.key, required this.initialWeek});

  static Future<void> open(int week) =>
      Get.to<void>(() => PregnancyWeekPage(initialWeek: week))!;

  @override
  State<PregnancyWeekPage> createState() => _PregnancyWeekPageState();
}

class _PregnancyWeekPageState extends State<PregnancyWeekPage> {
  late int _week = widget.initialWeek.clamp(4, 40);
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerChip(animate: false),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Deixa a semana escolhida visível no seletor.
  void _centerChip({bool animate = true}) {
    if (!_scroll.hasClients) return;
    const chip = 52.0;
    final target = ((_week - 4) * chip - 120).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (!animate) {
      _scroll.jumpTo(target);
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _select(int week) {
    setState(() => _week = week);
    _centerChip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PabColors.background,
      body: GetBuilder<PregnancyController>(
        init: PregnancyController.to,
        builder: (c) {
          final current = c.pregnancy?.week;
          final data = c.weekData(_week);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  PregTopBar(
                    title: 'Semana $_week',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PabColors.soft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trimesterLabel(_week),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PabColors.softText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 37,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _WeekChip(
                        week: i + 4,
                        selected: i + 4 == _week,
                        future: current != null && i + 4 > current,
                        onTap: () => _select(i + 4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        _Illustration(c: c, week: _week, data: data),
                        if (data?.reviewed ?? false) ...[
                          if (data!.baby.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const PregSectionTitle('O bebê esta semana'),
                            const SizedBox(height: 12),
                            TipsCard(
                              tips: data.baby,
                              icon: Icons.child_care_rounded,
                            ),
                          ],
                          if (data.mother.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const PregSectionTitle('No seu corpo'),
                            const SizedBox(height: 12),
                            TipsCard(
                              tips: data.mother,
                              icon: Icons.spa_outlined,
                              iconBackground: PabColors.lilac,
                              iconColor: PabColors.ink,
                            ),
                          ],
                          if (data.consult.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const PregSectionTitle(
                              'Para conversar com sua médica',
                            ),
                            const SizedBox(height: 12),
                            TipsCard(
                              tips: data.consult,
                              icon: Icons.chat_bubble_outline_rounded,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 16),
                          const _InReview(),
                        ],
                        const SizedBox(height: 24),
                        AlertSignsCard(data: data),
                        const SizedBox(height: 16),
                        const PregnancyNoticeCard(
                          title: 'Como você está se sentindo?',
                          text:
                              'As informações aqui são gerais e não substituem '
                              'o pré-natal. Se precisar conversar sobre '
                              'emoções, ansiedade ou mudanças, a Pablife tem '
                              'psicólogos para te ouvir.',
                          button: 'Conversar com um psicólogo',
                        ),
                      ],
                    ),
                  ),
                  if (current != null)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        16 + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: PabColors.line)),
                      ),
                      child: PregPrimaryButton(
                        label: 'Registrar nesta semana',
                        icon: Icons.add_rounded,
                        onPressed: () => PregnancyRecordPage.open(
                          date: _dateIn(c.pregnancy!, _week),
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

  /// Hoje, se [week] é a atual; senão o último dia da semana (sem passar de
  /// hoje).
  DateTime? _dateIn(Pregnancy p, int week) {
    if (week == p.week) return null;
    final end = p.dum.add(Duration(days: week * 7 + 6));
    final today = DateUtils.dateOnly(DateTime.now());
    return end.isAfter(today) ? today : end;
  }
}

class _WeekChip extends StatelessWidget {
  final int week;
  final bool selected;
  final bool future;
  final VoidCallback onTap;

  const _WeekChip({
    required this.week,
    required this.selected,
    required this.future,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PabColors.ink
          : future
          ? PregColors.future
          : PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected || future
            ? BorderSide.none
            : const BorderSide(color: PabColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          child: Center(
            child: Text(
              '$week',
              semanticsLabel: 'Semana $week',
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? PabColors.onInk
                    : future
                    ? PabColors.muted
                    : PabColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final PregnancyController c;
  final int week;
  final PregnancyWeek? data;

  const _Illustration({required this.c, required this.week, this.data});

  String get _headline {
    if (week == 20) return 'Você chegou à metade da gestação';
    if (week >= 37) return 'O bebê já é considerado a termo';
    if (week == 13) return 'Fim do 1º trimestre';
    if (week == 27) return 'Fim do 2º trimestre';
    return 'Como o bebê está na semana $week';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          BabyImage(
            url: c.imageFor(week),
            size: 236,
            semantics: 'Ilustração do bebê na semana $week',
          ),
          const SizedBox(height: 16),
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          WeekStats(data: data, comparisonLabel: 'Tamanho de'),
          const SizedBox(height: 12),
          const Text(
            'Valores médios aproximados. Cada bebê cresce no seu ritmo. '
            'Não substitui o pré-natal.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.4, color: PabColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Enquanto o texto da semana não foi revisado por uma profissional.
class _InReview extends StatelessWidget {
  const _InReview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.fact_check_outlined, color: PabColors.softText),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'O conteúdo desta semana está sendo revisado por profissionais '
              'de saúde e aparece aqui em breve.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: PabColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
