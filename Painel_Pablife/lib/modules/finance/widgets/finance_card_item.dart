import 'package:flutter/material.dart';
import '../../../infra/models/professional_monthly_transfer_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class FinanceCardItem extends StatelessWidget {
  final ProfessionalMonthlyTransfer transfer;

  const FinanceCardItem({super.key, required this.transfer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.attach_money,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextDefault(
                        text: transfer.professionalName,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(height: 4),
                      TextDefault(
                        text: transfer.professionalType.displayName,
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]!
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDefault(
                      text: 'Consultas concluidas',
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]!
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      text: '${transfer.appointmentsCount}',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    TextDefault(
                      text: 'Pacientes unicos: ${transfer.distinctUsersCount}',
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]!
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextDefault(
                      text: 'Mês ${transfer.monthLabel}',
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]!
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      text:
                          'R\$ ${transfer.totalTransferAmount.toStringAsFixed(2)}',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.greenAccent
                          : AppColors.primaryGreen,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
