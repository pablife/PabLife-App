import 'package:flutter/material.dart';

import '../../../widgets/design_system/text_default.dart';

class GoalProgressCard extends StatelessWidget {
  final String goalName;
  final int daysCompleted;
  final int totalDays;
  final int percentage;
  final Color color;
  final bool isCompleted;
  final bool isExpired;
  final VoidCallback? onTap;

  const GoalProgressCard({
    super.key,
    required this.goalName,
    required this.daysCompleted,
    required this.totalDays,
    required this.percentage,
    required this.color,
    this.isCompleted = false,
    this.isExpired = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawPercentage = percentage.toDouble();
    final percentageFactor = rawPercentage <= 0
        ? 0.05
        : (rawPercentage / 100).clamp(0.05, 1.0);

    final lightColor = color.withValues(alpha: 0.3);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  widthFactor: percentageFactor,
                  heightFactor: 1.0,
                  child: Container(decoration: BoxDecoration(color: color)),
                ),
              ),
            ),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 28,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextDefault(
                              goalName,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            TextDefault(
                              isCompleted
                                  ? 'Concluído em ($daysCompleted) dias'
                                  : isExpired
                                  ? 'Dias decorridos ($daysCompleted/$totalDays) (Prazo expirado)'
                                  : 'Dias decorridos ($daysCompleted/$totalDays)',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),

                      if (isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ] else ...[
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 20),
                      ],

                      TextDefault(
                        '$percentage%',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
