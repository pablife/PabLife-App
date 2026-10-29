import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../controllers/professional_selected_day_controller.dart';
import '../widgets/agenda_base_layout.dart';
import '../../../widgets/design_system/expandable_action_fab.dart';

class ProfessionalSelectedDayPage extends StatelessWidget {
  const ProfessionalSelectedDayPage({super.key});

  static const String route = '/professional-selected-day';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalSelectedDayController>(
      builder: (controller) {
        final filters = [
          const AgendaFilterOption(id: 'all', label: 'Todos'),
          const AgendaFilterOption(id: 'todo', label: 'A Fazer'),
          const AgendaFilterOption(id: 'completed', label: 'Realizados'),
        ];

        final headerInfo = AgendaHeaderInfo(
          primaryTitle: 'Consultas',
          primarySubtitle: '${controller.scheduledCount} Agendadas',
          secondaryTitle: 'Horários',
          secondarySubtitle: '${controller.availableCount} Disponíveis',
        );

        final now = DateTime.now();
        final isToday =
            controller.selectedDateTime.year == now.year &&
            controller.selectedDateTime.month == now.month &&
            controller.selectedDateTime.day == now.day;

        final hourBlocks = _buildHourBlocks(controller);

        return AgendaBaseLayout(
          selectedDateTime: controller.selectedDateTime,
          dateLabel: controller.selectedDate,
          monthLabel: controller.selectedMonth,
          weekdayLabel: controller.selectedWeekday,
          headerInfo: headerInfo,
          filters: filters,
          selectedFilterId: controller.currentFilter.name,
          onFilterSelected: (id) => controller.changeFilter(
            ProfessionalSelectedDayFilter.values.firstWhere(
              (filter) => filter.name == id,
              orElse: () => ProfessionalSelectedDayFilter.all,
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
            expandedWidth: 150,
            actions: [
              ExpandableFabAction(
                icon: Icons.schedule,
                onTap: () => controller.openCreateScheduleSlotBottomSheet(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<AgendaHourBlock> _buildHourBlocks(
    ProfessionalSelectedDayController controller,
  ) {
    final itemsByHour = <int, List<AgendaCardData>>{};
    final slots = controller.filteredSlots;

    for (final slot in slots) {
      final localStart = slot.startAt.toLocal();
      final hour = localStart.hour;
      final card = _mapSlotToCard(controller, slot);
      itemsByHour.putIfAbsent(hour, () => []).add(card);
    }

    return List.generate(24, (hour) {
      final items = itemsByHour[hour] ?? [];
      final isHighlighted =
          controller.highlightedHour == hour &&
          items.any((item) => !item.isPlaceholder);
      return AgendaHourBlock(
        hour: hour,
        items: items,
        isHighlighted: isHighlighted,
      );
    });
  }

  AgendaCardData _mapSlotToCard(
    ProfessionalSelectedDayController controller,
    ProfessionalScheduleSlot slot,
  ) {
    final appointment = slot.appointment;
    if (appointment == null) {
      return AgendaCardData(
        id: slot.id,
        title: 'Disponível',
        timeLabel: slot.timeLabel,
        backgroundColor: const Color(0xFFAEBEEC),
        icon: Icons.schedule,
        iconColor: AppColors.aquaText,
        titleColor: AppColors.aquaText,
        timeColor: AppColors.aquaText,
        trailing: GestureDetector(
          onTap: () => controller.promptRemoveSlot(slot),
          child: Icon(
            Icons.delete_outline,
            color: AppColors.aquaText,
            size: 20,
          ),
        ),
        isPlaceholder: true,
      );
    }

    Color backgroundColor;
    String? statusLabel;
    Color statusColor = Colors.white.withValues(alpha: 0.2);
    bool strikeThrough = false;

    if (appointment.isCompleted) {
      backgroundColor = const Color(0xFF0C8DA1);
      strikeThrough = true;
      statusLabel = 'Realizada';
    } else if (appointment.isOngoing) {
      backgroundColor = const Color(0xFF00C2A8);
      statusLabel = 'Agora';
    } else {
      backgroundColor = const Color(0xFF3065FF);
      statusLabel = null;
      statusColor = Colors.white.withValues(alpha: 0.25);
    }

    return AgendaCardData(
      id: appointment.id,
      title: 'Consulta ${appointment.patientName}',
      timeLabel: DateFormat('HH:mm').format(appointment.startAt.toLocal()),
      backgroundColor: backgroundColor,
      icon: Icons.favorite_border,
      iconColor: Colors.white,
      titleColor: Colors.white,
      timeColor: Colors.white,
      strikeThrough: strikeThrough,
      statusLabel: statusLabel,
      statusBackgroundColor: statusColor,
    );
  }
}
