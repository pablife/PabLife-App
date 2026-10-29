import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../infra/models/professional_schedule_slot.dart';
import '../controllers/professional_calendar_controller.dart';
import '../controllers/interactive_calendar_controller.dart';
import '../widgets/agenda_base_layout.dart';
import '../widgets/calendar_month_selector_widget.dart';
import '../widgets/interactive_calendar_base.dart';
import '../../../widgets/design_system/expandable_action_fab.dart';
import 'professional_selected_day_page.dart';

class ProfessionalCalendarTabPage extends StatefulWidget {
  const ProfessionalCalendarTabPage({super.key});

  static const String route = '/professional-calendar';

  @override
  State<ProfessionalCalendarTabPage> createState() =>
      _ProfessionalCalendarTabPageState();
}

class _ProfessionalCalendarTabPageState
    extends State<ProfessionalCalendarTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _todayScrollTrigger = 0;
  int _calendarScrollTrigger = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (_tabController.index == 0) {
      setState(() {
        _todayScrollTrigger += 1;
      });
      if (Get.isRegistered<ProfessionalCalendarController>()) {
        Get.find<ProfessionalCalendarController>().loadDailySchedule();
      }
    } else if (_tabController.index == 1) {
      setState(() {
        _calendarScrollTrigger += 1;
      });
      if (Get.isRegistered<InteractiveCalendarController>()) {
        Get.find<InteractiveCalendarController>().loadCalendarData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF082C32),
      body: Column(
        children: [
          SizedBox(height: statusBarHeight + 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TodayTabContent(scrollTrigger: _todayScrollTrigger),
                _CalendarTabContent(scrollTrigger: _calendarScrollTrigger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3A42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF0C8DA1),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFC1CDFF),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Instrument Sans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Instrument Sans',
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Hoje'),
          Tab(text: 'Calendário'),
        ],
      ),
    );
  }
}

class _TodayTabContent extends StatelessWidget {
  const _TodayTabContent({required this.scrollTrigger});

  final int scrollTrigger;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalCalendarController>(
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

        final hourBlocks = _buildHourBlocks(controller);

        return _TodayContent(
          controller: controller,
          filters: filters,
          hourBlocks: hourBlocks,
          headerInfo: headerInfo,
          scrollTrigger: scrollTrigger,
        );
      },
    );
  }

  List<AgendaHourBlock> _buildHourBlocks(
    ProfessionalCalendarController controller,
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
    ProfessionalCalendarController controller,
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

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.controller,
    required this.filters,
    required this.hourBlocks,
    required this.headerInfo,
    required this.scrollTrigger,
  });

  final ProfessionalCalendarController controller;
  final List<AgendaFilterOption> filters;
  final List<AgendaHourBlock> hourBlocks;
  final AgendaHeaderInfo headerInfo;
  final int scrollTrigger;

  ProfessionalAgendaFilter _mapFilterFromId(String id) {
    return ProfessionalAgendaFilter.values.firstWhere(
      (filter) => filter.name == id,
      orElse: () => ProfessionalAgendaFilter.all,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AgendaBaseLayout(
          selectedDateTime: controller.selectedDateTime,
          dateLabel: controller.selectedDate,
          monthLabel: controller.selectedMonth,
          weekdayLabel: controller.selectedWeekday,
          headerInfo: headerInfo,
          filters: filters,
          selectedFilterId: controller.currentFilter.name,
          onFilterSelected: (id) =>
              controller.changeFilter(_mapFilterFromId(id)),
          hourBlocks: hourBlocks,
          highlightedHour: controller.highlightedHour,
          scrollToCurrentHour: true,
          scrollTargetHour: controller.scrollTargetHour,
          scrollTrigger: scrollTrigger + controller.scrollTrigger,
          onScrollTargetConsumed: controller.clearScrollTarget,
          isLoading: controller.isLoading,
          floatingButton: ExpandableActionFab(
            expandedWidth: 150,
            actions: [
              ExpandableFabAction(
                icon: Icons.schedule,
                onTap: () => controller.openCreateScheduleSlotBottomSheet(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarTabContent extends StatelessWidget {
  const _CalendarTabContent({required this.scrollTrigger});

  final int scrollTrigger;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InteractiveCalendarController>(
      init: Get.isRegistered<InteractiveCalendarController>()
          ? Get.find<InteractiveCalendarController>()
          : Get.put(InteractiveCalendarController()),
      builder: (controller) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC1CDFF)),
          );
        }

        final calendarDays = _buildCalendarDays(controller);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
            ),
            Expanded(
              child: InteractiveCalendarBase(
                days: calendarDays,
                scrollToToday: true,
                scrollTrigger: scrollTrigger,
                onDayTap: (date) {
                  Get.toNamed(
                    ProfessionalSelectedDayPage.route,
                    arguments: date,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<CalendarDayData> _buildCalendarDays(
    InteractiveCalendarController controller,
  ) {
    return controller.daysInMonth.map((dayData) {
      final date = dayData['date'] as DateTime;
      final appointmentsCount = dayData['appointmentsCount'] as int? ?? 0;
      final availableSlots =
          dayData['availableSlots'] as List<ProfessionalScheduleSlot>? ?? [];

      final events = <CalendarEventData>[];

      // Adicionar consultas marcadas
      if (appointmentsCount > 0) {
        final consultaLabel = appointmentsCount == 1
            ? 'consulta marcada'
            : 'consultas marcadas';
        events.add(
          CalendarEventData(
            id: 'appointments',
            label: consultaLabel,
            count: appointmentsCount,
            color: const Color(0xFF3065FF),
            customLabel: '$appointmentsCount $consultaLabel',
          ),
        );
      }

      // Adicionar horários disponíveis (mostrar os horários)
      for (final slot in availableSlots) {
        final timeLabel = DateFormat('HH:mm').format(slot.startAt.toLocal());
        events.add(
          CalendarEventData(
            id: 'slot_${slot.id}',
            label: 'disponível',
            count: 1,
            color: const Color(0xFF00C2A8),
            customLabel: '$timeLabel disponível',
          ),
        );
      }

      return CalendarDayData(date: date, events: events);
    }).toList();
  }
}
