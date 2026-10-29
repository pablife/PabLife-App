import 'package:flutter/material.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../infra/models/home_view_models.dart';

class UserHomeTaskButtonWidget extends StatelessWidget {
  final TaskViewModel task;
  final VoidCallback onTap;

  const UserHomeTaskButtonWidget({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawPercentage = task.percentage.toDouble();
    final percentageFactor = rawPercentage <= 0
        ? 0.05
        : (rawPercentage / 100).clamp(0.05, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffAEBEEC),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percentageFactor,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xff0C8DA1)),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 28,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextDefault(
                          task.label,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 20),
                      TextDefault(
                        '${task.percentage}%',
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
