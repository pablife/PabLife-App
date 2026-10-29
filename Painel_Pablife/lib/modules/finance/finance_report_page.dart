import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'finance_report_controller.dart';
import 'widgets/finance_filter_bar.dart';
import 'widgets/finance_report_list.dart';
import 'widgets/finance_card_item.dart';
import 'widgets/pagination_widget.dart';

class FinanceReportPage extends StatelessWidget {
  const FinanceReportPage({super.key});

  static const route = '/finance-report';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Financeiro');

    return GetBuilder<FinanceReportController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: AppWidgetLoading()));
        }

        return Scaffold(
          body: Column(
            children: [
              FinanceFilterBar(controller: controller),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período: ${controller.currentPeriodLabel}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total a pagar: ${controller.formatCurrency(controller.totalTransferAmount)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    ViewModeToggle(
                      currentMode: controller.viewMode,
                      onModeChanged: controller.setViewMode,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: controller.viewMode.isGrid
                          ? _buildGridView(controller)
                          : FinanceReportList(controller: controller),
                    ),
                    PaginationWidget(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridView(FinanceReportController controller) {
    if (controller.sortedTransfers.isEmpty) {
      return const Center(child: Text('Nenhum dado encontrado'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largura/altura alvo para manter cards consistentes; só varia colunas.
        const targetCardWidth = 360.0;
        const targetCardHeight = 240.0;
        final columns = (constraints.maxWidth / targetCardWidth).floor().clamp(
          1,
          6,
        );

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: targetCardHeight,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.sortedTransfers.length,
          itemBuilder: (context, index) {
            final transfer = controller.sortedTransfers[index];

            return FinanceCardItem(transfer: transfer);
          },
        );
      },
    );
  }
}
