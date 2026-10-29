import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/interactive_calendar_controller.dart';
import '../widgets/calendar_month_selector_widget.dart';
import '../widgets/interactive_calendar_base.dart';
import '../../../shared/themes/app_colors.dart';
import 'selected_day_page.dart';

class InteractiveCalendarPage extends StatelessWidget {
  const InteractiveCalendarPage({super.key});

  static const route = '/calendar/interactive';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InteractiveCalendarController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF082C32),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.second),
            ),
          );
        }

        final calendarDays = _buildCalendarDays(controller);

        return Scaffold(
          backgroundColor: const Color(0xFF082C32),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A3A42),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFC1CDFF),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CalendarMonthSelectorWidget(
                          currentMonth: DateTime(
                            controller.selectedYear,
                            controller.selectedMonth,
                          ),
                          onChangeMonth: (offset) {
                            final newMonth = DateTime(
                              controller.selectedYear,
                              controller.selectedMonth + offset,
                            );
                            controller.changeMonth(newMonth);
                          },
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveCalendarBase(
                    days: calendarDays,
                    scrollToToday: true,
                    onDayTap: (date) {
                      Get.toNamed(SelectedDayPage.route, arguments: date);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CalendarDayData> _buildCalendarDays(
    InteractiveCalendarController controller,
  ) {
    return controller.daysInMonth.map((dayData) {
      final date = dayData['date'] as DateTime;
      final tasksCount = dayData['tasksCount'] as int? ?? 0;
      final notesCount = dayData['notesCount'] as int? ?? 0;
      final appointmentsCount = dayData['appointmentsCount'] as int? ?? 0;

      final events = <CalendarEventData>[];

      if (tasksCount > 0) {
        events.add(
          CalendarEventData(
            id: 'tasks',
            label: tasksCount == 1 ? 'Tarefa' : 'Tarefas',
            count: tasksCount,
            color: const Color(0xFF00C2A8),
          ),
        );
      }

      if (notesCount > 0) {
        events.add(
          CalendarEventData(
            id: 'notes',
            label: notesCount == 1 ? 'Anotação' : 'Anotações',
            count: notesCount,
            color: const Color(0xFFD2CC61),
          ),
        );
      }

      if (appointmentsCount > 0) {
        events.add(
          CalendarEventData(
            id: 'appointments',
            label: appointmentsCount == 1 ? 'Consulta' : 'Consultas',
            count: appointmentsCount,
            color: const Color(0xFF3065FF),
          ),
        );
      }

      return CalendarDayData(date: date, events: events);
    }).toList();
  }
}
