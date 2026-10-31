import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import 'coupon_owner_detail_page.dart';
import 'coupons_controller.dart';
import 'widgets/coupon_kpi_card.dart';

/// Aba "Visão geral": resultados dos cupons, gráfico por mês e ranking dos
/// titulares.
class CouponsOverviewPage extends StatelessWidget {
  const CouponsOverviewPage({super.key});

  static const route = '/visao-geral';

  static const _usesColor = AppColors.info;
  static const _firstColor = Color(0xFF9C27B0);
  static const _convColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Visão geral dos cupons');
    return GetBuilder<CouponsController>(
      builder: (controller) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final totals = controller.totals;
        final months = controller.monthly();

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  CouponKpiCard(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Usaram cupom',
                    value: '${totals.users}',
                    hint: '${totals.inFreePeriod} no período grátis',
                    color: _usesColor,
                  ),
                  CouponKpiCard(
                    icon: Icons.medical_services_outlined,
                    label: 'Fizeram a 1ª consulta',
                    value: '${totals.firstConsultations}',
                    hint:
                        '${percent(totals.firstConsultationRate)} dos usuários',
                    color: _firstColor,
                  ),
                  CouponKpiCard(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Viraram assinantes',
                    value: '${totals.conversions}',
                    hint: '${percent(totals.conversionRate)} de conversão',
                    color: _convColor,
                  ),
                  CouponKpiCard(
                    icon: Icons.payments_outlined,
                    label: 'Comissões a pagar',
                    value: money(controller.totalCommission),
                    hint: 'Somando todos os titulares',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextDefault(
                        text: 'Últimos 6 meses',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 16,
                        children: [
                          _Legend(color: _usesColor, label: 'Usos de cupom'),
                          _Legend(color: _firstColor, label: '1ª consulta'),
                          _Legend(
                            color: _convColor,
                            label: 'Viraram assinantes',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= months.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        months[i].label,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < months.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barsSpace: 4,
                                  barRods: [
                                    _rod(months[i].uses, _usesColor),
                                    _rod(
                                      months[i].firstConsultations,
                                      _firstColor,
                                    ),
                                    _rod(months[i].conversions, _convColor),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const TextDefault(
                text: 'Ranking dos titulares',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              if (controller.owners.isEmpty)
                const TextDefault(
                  text: 'Cadastre titulares na aba "Titulares".',
                  color: AppColors.textSecondary,
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Titular')),
                        DataColumn(label: Text('Usuários'), numeric: true),
                        DataColumn(label: Text('1ª consulta'), numeric: true),
                        DataColumn(label: Text('Assinantes'), numeric: true),
                        DataColumn(label: Text('Conversão'), numeric: true),
                        DataColumn(label: Text('Comissão'), numeric: true),
                      ],
                      rows: [
                        for (final (i, (owner, r))
                            in controller.ownerRanking.indexed)
                          DataRow(
                            onSelectChanged: (_) => Get.toNamed(
                              CouponOwnerDetailPage.route,
                              arguments: owner.id,
                            ),
                            cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(owner.name)),
                              DataCell(Text('${r.users}')),
                              DataCell(Text('${r.firstConsultations}')),
                              DataCell(Text('${r.conversions}')),
                              DataCell(Text(percent(r.conversionRate))),
                              DataCell(
                                Text(money(controller.commissionOf(owner))),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static BarChartRodData _rod(int value, Color color) => BarChartRodData(
    toY: value.toDouble(),
    color: color,
    width: 12,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        TextDefault(text: label, fontSize: 12),
      ],
    );
  }
}
