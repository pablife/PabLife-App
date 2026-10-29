import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class InteractiveCalendarCardWidget extends StatelessWidget {
  final DateTime date;
  final int tasksCount;
  final int notesCount;
  final int appointmentsCount;
  final bool isToday;
  final VoidCallback? onTap;

  const InteractiveCalendarCardWidget({
    super.key,
    required this.date,
    this.tasksCount = 0,
    this.notesCount = 0,
    this.appointmentsCount = 0,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayNumber = date.day.toString();
    final monthLabel = DateFormat('MMM', 'pt_BR').format(date).toUpperCase();
    final weekdayLabel = DateFormat('EEEE', 'pt_BR')
        .format(date)
        .replaceFirst(
          RegExp(r'^.'),
          DateFormat('EEEE', 'pt_BR').format(date)[0].toUpperCase(),
        );

    final hasEvents = tasksCount > 0 || notesCount > 0 || appointmentsCount > 0;
    final cardColor = _getCardColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSection(dayNumber, monthLabel, weekdayLabel),
              if (hasEvents) ...[
                const SizedBox(width: 16),
                Expanded(child: _buildEventsSection()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    if (isToday) {
      return AppColors.second.withValues(alpha: 0.8);
    }

    final colors = [
      const Color(0xFFE8D5E2), // Rosa claro
      const Color(0xFFD4C5D9), // Lilás
      const Color(0xFFD5C4C4), // Rosa acinzentado
      const Color(0xFFCDE5DB), // Verde água claro
      const Color(0xFFD9E2C8), // Verde claro
      const Color(0xFFE5DCC5), // Bege
    ];

    return colors[date.day % colors.length];
  }

  Widget _buildDateSection(
    String dayNumber,
    String monthLabel,
    String weekdayLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextDefault(
          weekdayLabel,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.aquaText,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dayNumber,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.aquaText,
                height: 1,
                fontFamily: 'Instrument Sans',
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.aquaText,
                  fontFamily: 'Instrument Sans',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    final events = <Widget>[];

    if (tasksCount > 0) {
      events.add(
        _buildEventChip(
          '$tasksCount ${tasksCount == 1 ? 'Tarefa' : 'Tarefas'}',
          const Color(0xFF00C2A8),
        ),
      );
    }

    if (notesCount > 0) {
      events.add(
        _buildEventChip(
          '$notesCount ${notesCount == 1 ? 'Nota' : 'Notas'}',
          const Color(0xFFD2CC61),
        ),
      );
    }

    if (appointmentsCount > 0) {
      events.add(
        _buildEventChip(
          '$appointmentsCount ${appointmentsCount == 1 ? 'Consulta' : 'Consultas'}',
          const Color(0xFF3065FF),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: events,
    );
  }

  Widget _buildEventChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextDefault(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
