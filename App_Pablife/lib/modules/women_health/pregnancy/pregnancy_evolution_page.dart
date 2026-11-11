import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import 'pregnancy_controller.dart';
import 'pregnancy_models.dart';
import 'pregnancy_week_page.dart';
import 'pregnancy_widgets.dart';

/// "Do início até a semana 40": reta final, comprimento semana a semana e a
/// galeria das semanas de referência.
class PregnancyEvolutionPage extends StatelessWidget {
  const PregnancyEvolutionPage({super.key});

  static Future<void> open() =>
      Get.to<void>(() => const PregnancyEvolutionPage())!;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final pad = wide ? 40.0 : 20.0;
    return Scaffold(
      backgroundColor: PabColors.background,
      body: GetBuilder<PregnancyController>(
        init: PregnancyController.to,
        builder: (c) {
          final p = c.pregnancy;
          return Column(
            children: [
              const PregTopBar(title: 'Evolução da gestação'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Do início até a semana 40',
                              style: TextStyle(
                                fontSize: wide ? 30 : 24,
                                fontWeight: FontWeight.w800,
                                color: PabColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Veja como o bebê vai crescendo ao longo da '
                              'gestação. Tamanhos e pesos são médias '
                              'aproximadas; as ilustrações são estilizadas.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: PabColors.muted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _FinalStretch(c: c, p: p, wide: wide),
                            const SizedBox(height: 32),
                            const PregSectionTitle(
                              'Comprimento do bebê, semana a semana',
                            ),
                            const SizedBox(height: 12),
                            _LengthChart(c: c, current: p?.week),
                            const SizedBox(height: 32),
                            _Gallery(c: c, current: p?.week, wide: wide),
                            const SizedBox(height: 24),
                            const PregnancyNoticeCard(
                              text:
                                  'Tamanhos, pesos e datas são médias e podem '
                                  'variar. Esta ferramenta não substitui o '
                                  'pré-natal: converse sempre com sua médica '
                                  'ou obstetra.',
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
        },
      ),
    );
  }
}

class _FinalStretch extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy? p;
  final bool wide;

  const _FinalStretch({required this.c, required this.p, required this.wide});

  @override
  Widget build(BuildContext context) {
    final w40 = c.weekData(40);
    final facts = <String>[
      ?c.weekData(37)?.baby.firstOrNull?.text,
      ?c.weekData(36)?.baby.firstOrNull?.text,
      'Contrações regulares, perda de líquido ou sangramento: procure sua '
          'médica ou a maternidade.',
    ];
    final image = BabyImage(
      url: w40?.imageUrl,
      size: wide ? 260 : 200,
      semantics:
          'Ilustração do bebê na semana 40, com a cabeça para baixo, pronto '
          'para nascer',
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: PabColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '3º trimestre · reta final',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PabColors.softText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Semana 40',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: PabColors.ink,
          ),
        ),
        const Text(
          'O bebê está pronto para conhecer você.',
          style: TextStyle(fontSize: 15, color: PabColors.muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Comprimento',
                value: w40?.lengthLabel ?? '—',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(label: 'Peso', value: w40?.weightLabel ?? '—'),
            ),
            if (p != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Parto previsto',
                  value: dateBr.format(p!.dpp),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        for (final f in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: PabColors.softText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: PabColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(28),
      ),
      child: wide
          ? Row(
              children: [
                image,
                const SizedBox(width: 32),
                Expanded(child: info),
              ],
            )
          : Column(children: [image, const SizedBox(height: 16), info]),
    );
  }
}

class _LengthChart extends StatelessWidget {
  final PregnancyController c;
  final int? current;

  const _LengthChart({required this.c, required this.current});

  @override
  Widget build(BuildContext context) {
    final weeks = c.weeks.where((w) => w.lengthCm != null).toList();
    if (weeks.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 8),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: Semantics(
        label:
            'Gráfico de barras do comprimento médio do bebê: de '
            '${formatCm(weeks.first.lengthCm!)} na semana ${weeks.first.week} '
            'a ${formatCm(weeks.last.lengthCm!)} na semana ${weeks.last.week}',
        child: BarChart(
          BarChartData(
            maxY: 55,
            gridData: const FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 10,
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  'Semana ${group.x}\n≈ ${formatCm(rod.toY)}',
                  const TextStyle(
                    color: PabColors.onInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 10,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PabColors.muted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => v.toInt() % 4 == 0
                      ? Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: PabColors.muted,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            barGroups: [
              for (final w in weeks)
                BarChartGroupData(
                  x: w.week,
                  barRods: [
                    BarChartRodData(
                      toY: w.lengthCm!,
                      width: 8,
                      borderRadius: BorderRadius.circular(3),
                      color: w.week == current
                          ? PabColors.softText
                          : current != null && w.week < current!
                          ? PabColors.pink
                          : PregColors.rest,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  final PregnancyController c;
  final int? current;
  final bool wide;

  const _Gallery({required this.c, required this.current, required this.wide});

  @override
  Widget build(BuildContext context) {
    final here = current == null ? null : nearestReferenceWeek(current!);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = wide ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final w in referenceWeeks)
              SizedBox(
                width: width,
                child: _GalleryItem(
                  week: w,
                  data: c.weekData(w),
                  isCurrent: w == here,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final int week;
  final PregnancyWeek? data;
  final bool isCurrent;

  const _GalleryItem({
    required this.week,
    required this.data,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final d = data;
    final comparison = d?.comparison == null
        ? ''
        : ' · tamanho de ${_withArticle(d!.comparison!)}';
    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isCurrent
            ? const BorderSide(color: PabColors.pink, width: 2)
            : const BorderSide(color: PabColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => PregnancyWeekPage.open(week),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BabyImage(
                url: d?.imageUrl,
                size: 96,
                semantics: 'Bebê na semana $week',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Semana $week',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PabColors.ink,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Você está aqui',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: PabColors.onInk,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d == null
                          ? ''
                          : '${d.lengthLabel} · ${d.weightLabel}$comparison',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PabColors.muted,
                      ),
                    ),
                    if (d != null && d.baby.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        d.baby.first.text,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: PabColors.ink,
                        ),
                      ),
                    ],
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

/// "Banana" → "uma banana", "Limão" → "um limão".
String _withArticle(String noun) {
  final lower = noun[0].toLowerCase() + noun.substring(1);
  const feminine = [
    'framboesa',
    'banana',
    'espiga',
    'berinjela',
    'azeitona',
    'maçã',
    'pera',
    'manga',
    'cenoura',
    'toranja',
    'couve',
    'alface',
    'semente',
    'lentilha',
  ];
  final f = feminine.any(lower.startsWith);
  return '${f ? 'uma' : 'um'} $lower';
}
