import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../infra/models/professional_appointment_model.dart';
import 'calendar_collapsed_card_widget.dart';
import 'calendar_expanded_card_widget.dart';

class CalendarDateCardWidget extends StatelessWidget {
  final int index;
  final String dateKey;
  final DateTime date;
  final int tasksCount;
  final int notesCount;
  final int appointmentsCount;
  final List<ProfessionalAppointmentModel> appointments;
  final bool isProfessional;
  final bool hasEvents;
  final bool isExpanded;
  final void Function(String) onToggleExpanded;
  final bool Function(DateTime) isToday;

  const CalendarDateCardWidget({
    super.key,
    required this.index,
    required this.dateKey,
    required this.date,
    required this.tasksCount,
    required this.notesCount,
    this.appointmentsCount = 0,
    this.appointments = const [],
    this.isProfessional = false,
    required this.hasEvents,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.isToday,
  });

  Color _getCardColor(int index, bool isExpanded) {
    if (isExpanded) return const Color(0xFF00343C);

    final colors = [
      const Color(0xFF001417),
      const Color(0xFF01181C),
      const Color(0xFF01424C),
      const Color(0xFF06505B),
      const Color(0xFF056574),
      const Color(0xFF0F8799),
    ];

    return colors[index % colors.length];
  }

  double _getCardHeight(DateTime date, bool hasEvents, bool isExpanded) {
    if (isExpanded) return 214;
    if (isToday(date)) return 94;
    return 61;
  }

  @override
  Widget build(BuildContext context) {
    final dayNumber = DateFormat('dd').format(date);
    final monthLabel = DateFormat('MMM', 'pt_BR').format(date).toUpperCase();
    final weekdayLabel = DateFormat('EEEE', 'pt_BR').format(date);

    final backgroundColor = _getCardColor(index, isExpanded);
    final minHeight = _getCardHeight(date, hasEvents, isExpanded);

    return GestureDetector(
      onTap: () => onToggleExpanded(dateKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(minHeight: minHeight),
        color: backgroundColor,
        child: isExpanded
            ? CalendarExpandedCardWidget(
                date: date,
                dayNumber: dayNumber,
                monthLabel: monthLabel,
                weekdayLabel: weekdayLabel,
                tasksCount: tasksCount,
                notesCount: notesCount,
                appointments: appointments,
                isProfessional: isProfessional,
              )
            : CalendarCollapsedCardWidget(
                date: date,
                dayNumber: dayNumber,
                monthLabel: monthLabel,
                tasksCount: tasksCount,
                notesCount: notesCount,
                appointmentsCount: appointmentsCount,
                isProfessional: isProfessional,
                isToday: isToday(date),
              ),
      ),
    );
  }
}
