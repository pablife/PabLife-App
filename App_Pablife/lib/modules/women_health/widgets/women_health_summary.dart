import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dashboard/dashboard_controller.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

/// Topo do modo: anel da trilha, fase atual e cartões com as estimativas.
class WomenHealthSummary extends StatelessWidget {
  final WomenHealthController controller;

  const WomenHealthSummary({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tracksPeriod =
        controller.trail == WomenTrail.cycle ||
        controller.trail == WomenTrail.conceive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 820;
        final hero = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WomenColors.plum,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _RingPainter(controller.ringFraction),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.ringValue,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: WomenColors.light,
                            ),
                          ),
                          Text(
                            controller.ringUnit,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: WomenColors.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.trail!.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: WomenColors.lightMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.heroTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: WomenColors.light,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.heroSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: WomenColors.lightMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: WomenColors.lilac,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'estimativa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: WomenColors.ink,
                            ),
                          ),
                        ),
                        if (tracksPeriod)
                          TextButton(
                            onPressed: controller.registerPeriodToday,
                            style: TextButton.styleFrom(
                              foregroundColor: WomenColors.rose,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 28),
                            ),
                            child: const Text(
                              'Minha menstruação veio hoje',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        final grid = _TilesGrid(tiles: controller.tiles);

        if (!wide) {
          return Column(children: [hero, const SizedBox(height: 12), grid]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: hero),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: grid),
            ],
          ),
        );
      },
    );
  }
}

class _TilesGrid extends StatelessWidget {
  final List<WomenTile> tiles;

  const _TilesGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    Widget tile(WomenTile t) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A466E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: WomenColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.note,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A466E),
              ),
            ),
          ],
        ),
      ),
    );

    Widget row(WomenTile a, WomenTile b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(a), const SizedBox(width: 12), tile(b)],
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        row(tiles[0], tiles[1]),
        const SizedBox(height: 12),
        row(tiles[2], tiles[3]),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;

  const _RingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      paint..color = WomenColors.ringTrack,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      paint..color = WomenColors.rose,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

/// Parte de baixo do modo: check-in do dia, avisos e cuidado.
class WomenHealthCareSection extends StatelessWidget {
  final WomenHealthController controller;

  const WomenHealthCareSection({super.key, required this.controller});

  void _openProfessionals() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeTab(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final care = womenCare[controller.trail]!;
    final selected = controller.todayCheckIn;
    final todayMood = womenMoodByLabel(selected);

    final checkIn = _Panel(
      children: [
        const Text('Como você está hoje?', style: _panelTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in controller.checkInOptions)
              Tooltip(
                message: option.label,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => controller.toggleCheckIn(option.label),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected == option.label
                          ? WomenColors.lilac
                          : Colors.white,
                      border: Border.all(
                        color: selected == option.label
                            ? WomenColors.violet
                            : WomenColors.line,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          todayMood == null
              ? 'Passe o mouse para ver cada humor e toque no de hoje. Ele '
                    'fica registrado no dia, na agenda.'
              : 'Hoje: ${todayMood.emoji} ${todayMood.label}. Registrado na '
                    'agenda.',
          style: _panelNote,
        ),
      ],
    );

    final notices = _Panel(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Notificações desta trilha', style: _panelTitle),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: WomenColors.soft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'em breve',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: WomenColors.plum,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final notice in care.notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 18,
                  color: WomenColors.violet,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: WomenColors.plum,
                        ),
                      ),
                      Text(notice.when, style: _panelNote),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final carePanel = _Panel(
      color: WomenColors.rose,
      children: [
        Text(
          care.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: WomenColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          care.text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: WomenColors.text,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _openProfessionals,
              style: FilledButton.styleFrom(
                backgroundColor: WomenColors.plum,
                foregroundColor: WomenColors.light,
              ),
              child: const Text('Agendar com psicóloga'),
            ),
            OutlinedButton(
              onPressed: _openProfessionals,
              style: OutlinedButton.styleFrom(
                foregroundColor: WomenColors.plum,
                side: const BorderSide(color: WomenColors.plum, width: 1.5),
              ),
              child: const Text('Falar com nutricionista'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          care.medical,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: WomenColors.text,
          ),
        ),
      ],
    );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 820) {
              return Column(
                children: [
                  checkIn,
                  const SizedBox(height: 12),
                  notices,
                  const SizedBox(height: 12),
                  carePanel,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: checkIn),
                  const SizedBox(width: 12),
                  Expanded(child: notices),
                  const SizedBox(width: 12),
                  Expanded(child: carePanel),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          womenDisclaimer,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.5, color: WomenColors.muted),
        ),
      ],
    );
  }
}

const _panelTitle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: WomenColors.plum,
);

const _panelNote = TextStyle(
  fontSize: 12,
  height: 1.5,
  color: WomenColors.muted,
);

class _Panel extends StatelessWidget {
  final List<Widget> children;
  final Color color;

  const _Panel({required this.children, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
