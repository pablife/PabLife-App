import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../women_health_controller.dart';
import 'my_pregnancy_page.dart';
import 'pregnancy_controller.dart';
import 'pregnancy_models.dart';
import 'pregnancy_widgets.dart';

/// Cartões da trilha Gestação no Dashboard: "Minha gestação", "Como você
/// está hoje?" e o próximo passo da semana.
class PregnancyDashboardCards extends StatelessWidget {
  final WomenHealthController women;

  const PregnancyDashboardCards({super.key, required this.women});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PregnancyController>(
      init: PregnancyController.to,
      builder: (c) {
        final p = c.pregnancy;
        if (p == null) {
          return _Empty(loading: c.loading || !c.loaded);
        }
        final next = c.weekData(p.shownWeek)?.consult.firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PregnancyCard(pregnancy: p, controller: c),
            if (next != null) ...[
              const SizedBox(height: 14),
              NextStepCard(tip: next),
            ],
          ],
        );
      },
    );
  }
}

String milestone(Pregnancy p) {
  final w = p.week;
  if (w >= 37) return 'Reta final!';
  if (w == 20) return 'Metade do caminho!';
  if (w == 13 || w == 14) return 'Começo do 2º trimestre!';
  if (w == 27 || w == 28) return 'Começo do 3º trimestre!';
  return trimesterLabel(w);
}

class _PregnancyCard extends StatelessWidget {
  final Pregnancy pregnancy;
  final PregnancyController controller;

  const _PregnancyCard({required this.pregnancy, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = pregnancy;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PregColors.rest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Minha gestação',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PabColors.softText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trimesterLabel(p.week),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BabyImage(
                url: controller.imageFor(p.week),
                size: 116,
                semantics: 'Ilustração do bebê na semana ${p.week}',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semana ${p.week}',
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.weekAndDays,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: PabColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      milestone(p),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PabColors.softText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          WeekProgress(week: p.week),
          const SizedBox(height: 8),
          DueLine(pregnancy: p, dueLabel: 'Data provável do parto'),
          const SizedBox(height: 16),
          PregPrimaryButton(
            label: 'Ver evolução do bebê',
            onPressed: MyPregnancyPage.open,
          ),
          const SizedBox(height: 8),
          const Text(
            pregnancyDisclaimer,
            style: TextStyle(fontSize: 11, height: 1.5, color: PabColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Próximo passo da semana (vem do conteúdo revisado).
class NextStepCard extends StatelessWidget {
  final WeekTip tip;

  const NextStepCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: PabColors.softText,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title.replaceAll(RegExp(r'\.$'), ''),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: PabColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool loading;

  const _Empty({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(28),
      ),
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: PabColors.softText),
              ),
            )
          : const Text(
              'Informe a data da última menstruação na Saúde da Mulher para '
              'acompanhar a gestação semana a semana.',
              style: TextStyle(fontSize: 14, height: 1.5, color: PabColors.ink),
            ),
    );
  }
}
