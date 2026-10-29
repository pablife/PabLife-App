import 'package:flutter/material.dart';
import '../../controllers/professional_home_controller.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../shared/themes/app_colors.dart';

class ProfessionalHomeAppointmentsProgressWidget extends StatelessWidget {
  final ProfessionalHomeController controller;

  const ProfessionalHomeAppointmentsProgressWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final progress = controller.todayConsultationsProgress;

    if (progress == null) {
      return const SizedBox.shrink();
    }

    final percentage = (progress['percentage'] as num).toDouble();
    final percentageFactor = percentage <= 0
        ? 0.05
        : (percentage / 100).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextDefault(
            'Agendamentos',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.aquaText,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAEBEEC),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: percentageFactor,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0C8DA1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 28,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: TextDefault(
                            'Consultas hoje',
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
                          '${percentage.round()}%',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
