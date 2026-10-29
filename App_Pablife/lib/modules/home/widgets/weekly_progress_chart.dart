import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../infra/models/home_view_models.dart';

class WeeklyProgressChart extends StatelessWidget {
  final List<WeeklyProgressViewModel> weeklyData;
  final int totalTasks;

  const WeeklyProgressChart({
    super.key,
    required this.weeklyData,
    this.totalTasks = 7,
  });

  @override
  Widget build(BuildContext context) {
    final maxCompleted = weeklyData.isEmpty
        ? 5
        : weeklyData.map((d) => d.completed).reduce((a, b) => a > b ? a : b);
    final maxTotal = weeklyData.isEmpty
        ? 5
        : weeklyData.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final calculatedMaxY =
        (maxTotal > maxCompleted ? maxTotal : maxCompleted) + 1;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: calculatedMaxY > 0 ? calculatedMaxY.toDouble() : 5,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.aqua,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              tooltipMargin: 8,
              tooltipRoundedRadius: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final completed = weeklyData[groupIndex].completed;
                final total = weeklyData[groupIndex].total;
                return BarTooltipItem(
                  'Tarefas\n$completed de $total Realizadas',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextDefault(
                        weeklyData[value.toInt()].day,
                        fontSize: 14,
                        color: AppColors.aquaText,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 36,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final completed = data.completed;
            final total = data.total;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: completed.toDouble(),
                  color: const Color(0xff0C8DA1),
                  width: 40,
                  borderRadius: BorderRadius.circular(25),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    color: Colors.grey.withAlpha(77),
                    toY: total.toDouble(),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
