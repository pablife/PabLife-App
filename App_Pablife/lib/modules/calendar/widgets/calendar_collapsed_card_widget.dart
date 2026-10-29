import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/design_system/text_default.dart';

class CalendarCollapsedCardWidget extends StatelessWidget {
  final DateTime date;
  final String dayNumber;
  final String monthLabel;
  final int tasksCount;
  final int notesCount;
  final int appointmentsCount;
  final bool isProfessional;
  final bool isToday;

  const CalendarCollapsedCardWidget({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.monthLabel,
    required this.tasksCount,
    required this.notesCount,
    this.appointmentsCount = 0,
    this.isProfessional = false,
    required this.isToday,
  });

  String _getAvailabilityText() {
    if (isProfessional) {
      if (appointmentsCount == 0) return 'Sem consultas';
      return '$appointmentsCount Consulta${appointmentsCount > 1 ? 's' : ''}';
    }

    if (tasksCount == 0 && notesCount == 0) {
      return 'Sem eventos';
    }

    final parts = <String>[];
    if (tasksCount > 0) {
      parts.add('$tasksCount Tarefa${tasksCount > 1 ? 's' : ''}');
    }
    if (notesCount > 0) {
      parts.add('$notesCount Anotaç${notesCount > 1 ? 'ões' : 'ão'}');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = isToday ? 36.0 : 24.0;
    final dividerHeight = isToday ? 54.0 : 34.0;
    final monthNumber = DateFormat('MM').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: TextDefault(
              '$dayNumber.$monthNumber',
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFC1CDFF),
            ),
          ),
          const SizedBox(width: 46),
          Container(
            width: 3,
            height: dividerHeight,
            color: const Color(0xFFC1CDFF),
          ),
          const SizedBox(width: 46),
          Expanded(
            child: TextDefault(
              _getAvailabilityText(),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC1CDFF),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
