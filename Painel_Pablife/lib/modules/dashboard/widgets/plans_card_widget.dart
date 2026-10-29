import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_card_widget.dart';
import '../../../widgets/design_system/text_default.dart';
import '../dashboard_controller.dart';

class PlansCardWidget extends StatelessWidget {
  final double width;
  final DashboardController controller;

  const PlansCardWidget({
    super.key,
    required this.width,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_membership_outlined,
                    color: Color.fromARGB(255, 0, 255, 8),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: TextDefault(
                    text: 'Planos',
                    fontSize: 18,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.subscriptionsByPlan.isEmpty)
              const TextDefault(
                text: 'Nenhuma assinatura ativa',
                fontSize: 17,
                color: AppColors.white,
              )
            else
              ...controller.subscriptionsByPlan.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextDefault(
                          text: entry.key,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.white
                              : AppColors.textBlack,
                        ),
                      ),
                      TextDefault(
                        text: entry.value.toString(),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 255, 8),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
