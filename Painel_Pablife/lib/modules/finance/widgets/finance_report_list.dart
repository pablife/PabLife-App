import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../finance_report_controller.dart';

class FinanceReportList extends StatelessWidget {
  final FinanceReportController controller;

  const FinanceReportList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.sortedTransfers;

    if (items.isEmpty) {
      return const Center(
        child: TextDefault(
          text: 'Sem dados para o período/seleção',
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: TextDefault(
            text:
                'Consultas: ${controller.totalAppointments} • Pacientes únicos: ${controller.totalDistinctUsers} • Total a pagar: ${controller.formatCurrency(controller.totalTransferAmount)}',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transfer = items[index];

              return ListTile(
                leading: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.success,
                ),
                title: TextDefault(
                  text: transfer.professionalName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                subtitle: TextDefault(
                  text:
                      '${transfer.professionalType.displayName} • ${transfer.appointmentsCount} consultas • ${transfer.distinctUsersCount} pacientes',
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]!
                      : AppColors.textSecondary,
                ),
                trailing: Text(
                  controller.formatCurrency(transfer.totalTransferAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.greenAccent
                        : AppColors.primaryGreen,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
