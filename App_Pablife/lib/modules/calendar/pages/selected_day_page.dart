import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/design_system/text_default.dart';

import '../calendar_controller.dart';
import '../controllers/selected_day_controller.dart';
import '../widgets/agenda_base_layout.dart';
import '../../../widgets/design_system/expandable_action_fab.dart';

class SelectedDayPage extends StatelessWidget {
  const SelectedDayPage({super.key});

  static const String route = '/selected-day';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SelectedDayController>(
      builder: (controller) {
        final filters = [
          const AgendaFilterOption(id: 'all', label: 'Todas'),
          const AgendaFilterOption(id: 'todo', label: 'A Fazer'),
          const AgendaFilterOption(id: 'completed', label: 'Realizadas'),
        ];

        final hourBlocks = _buildHourBlocks(controller);

        final headerInfo = AgendaHeaderInfo(
          primaryTitle: 'Tarefas Agendadas',
          primarySubtitle: '${controller.tasksCount} Tarefas',
          secondaryTitle: 'Anotações',
          secondarySubtitle: '${controller.notesCount} Anotações',
        );

        final now = DateTime.now();
        final isToday =
            controller.selectedDateTime.year == now.year &&
            controller.selectedDateTime.month == now.month &&
            controller.selectedDateTime.day == now.day;

        return AgendaBaseLayout(
          selectedDateTime: controller.selectedDateTime,
          dateLabel: controller.selectedDate,
          monthLabel: controller.selectedMonth,
          weekdayLabel: controller.selectedWeekday,
          headerInfo: headerInfo,
          filters: filters,
          selectedFilterId: controller.currentFilter.name,
          onFilterSelected: (id) => controller.changeFilter(
            CalendarFilter.values.firstWhere(
              (filter) => filter.name == id,
              orElse: () => CalendarFilter.all,
            ),
          ),
          hourBlocks: hourBlocks,
          highlightedHour: controller.highlightedHour,
          scrollTargetHour: controller.scrollTargetHour,
          scrollTrigger: controller.scrollTrigger,
          scrollToCurrentHour: isToday,
          onScrollTargetConsumed: controller.clearScrollTarget,
          isLoading: controller.isLoading,
          showBackButton: true,
          onBackPressed: () => Get.back(),
          floatingButton: ExpandableActionFab(
            actions: [
              ExpandableFabAction(
                // icon: Icons.flag_outlined,
                iconWidget: Center(
                  child: TextDefault(
                    "M",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: controller.createGoal,
              ),
              ExpandableFabAction(
                // icon: Icons.check_circle_outline,
                iconWidget: Center(
                  child: TextDefault(
                    "T",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: controller.createTask,
              ),
              ExpandableFabAction(
                // icon: Icons.note_add_outlined,
                iconWidget: Center(
                  child: TextDefault(
                    "A",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: controller.createNote,
              ),
            ],
          ),
        );
      },
    );
  }

  List<AgendaHourBlock> _buildHourBlocks(SelectedDayController controller) {
    final itemsByHour = <int, List<AgendaCardData>>{};

    for (final item in controller.filteredItems) {
      final card = _mapCalendarItemToCard(item, controller);
      itemsByHour.putIfAbsent(item.hour, () => []).add(card);
    }

    return List.generate(24, (hour) {
      final items = itemsByHour[hour] ?? [];
      final isHighlighted =
          controller.highlightedHour == hour && items.isNotEmpty;
      return AgendaHourBlock(
        hour: hour,
        items: items,
        isHighlighted: isHighlighted,
      );
    });
  }

  AgendaCardData _mapCalendarItemToCard(
    CalendarItem item,
    SelectedDayController controller,
  ) {
    Color backgroundColor;
    IconData iconData;
    bool showToggle = false;

    switch (item.type) {
      case CalendarItemType.taskPending:
        backgroundColor = const Color(0xFF00C2A8);
        iconData = Icons.check_circle_outline;
        showToggle = true;
        break;
      case CalendarItemType.task:
        backgroundColor = item.isCompleted
            ? const Color(0xFF0C8DA1)
            : const Color(0xFF00C2A8);
        iconData = Icons.check_circle_outline;
        showToggle = true;
        break;
      case CalendarItemType.goal:
        backgroundColor = const Color(0xFF92CA4F);
        iconData = Icons.flag_outlined;
        showToggle = true;
        break;
      case CalendarItemType.note:
        backgroundColor = const Color(0xFFD2CC61);
        iconData = Icons.note_outlined;
        showToggle = true;
        break;
      case CalendarItemType.consultation:
        backgroundColor = const Color(0xFF3065FF);
        iconData = Icons.favorite_border;
        break;
    }

    debugPrint('Activity ID ${item.id}');

    return AgendaCardData(
      id: item.id,
      title: item.title,
      timeLabel: item.time,
      backgroundColor: backgroundColor,
      icon: iconData,
      iconColor: Colors.white,
      titleColor: Colors.white,
      timeColor: Colors.white,
      strikeThrough: item.isCompleted,
      showToggle: showToggle,
      isCompleted: item.isCompleted,
      onToggle: showToggle
          ? () => controller.toggleTaskStatus(item.id, !item.isCompleted)
          : null,
      onTap: () => controller.openActivityDetails(item),
    );
  }
}
