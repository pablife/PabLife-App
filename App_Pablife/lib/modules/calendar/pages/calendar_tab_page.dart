import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/design_system/text_default.dart';

import '../../../widgets/design_system/expandable_action_fab.dart';
import '../calendar_controller.dart';
import '../controllers/interactive_calendar_controller.dart';
import '../widgets/agenda_base_layout.dart';
import '../widgets/calendar_month_selector_widget.dart';
import '../widgets/interactive_calendar_base.dart';
import 'selected_day_page.dart';

class CalendarTabPage extends StatefulWidget {
  const CalendarTabPage({super.key});

  static const String route = '/calendar';

  @override
  State<CalendarTabPage> createState() => _CalendarTabPageState();
}

class _CalendarTabPageState extends State<CalendarTabPage>
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
    } else if (_tabController.index == 1) {
      setState(() {
        _calendarScrollTrigger += 1;
      });
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
          const SizedBox(height: 4),
          _buildBetaBadge(),
          const SizedBox(height: 4),
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

  Widget _buildBetaBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3A42),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00C2A8), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C2A8).withAlpha(38),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Beta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00C2A8),
              letterSpacing: 0.6,
            ),
          ),
        ),
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
    return GetBuilder<CalendarController>(
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

  List<AgendaHourBlock> _buildHourBlocks(CalendarController controller) {
    final itemsByHour = <int, List<AgendaCardData>>{};

    for (final item in controller.filteredItems) {
      final card = _mapCalendarItemToCard(item, controller);
      itemsByHour.putIfAbsent(item.hour, () => []).add(card);
    }

    return List.generate(24, (hour) {
      final items = itemsByHour[hour] ?? [];
      final isHighlighted =
          controller.highlightedHour == hour && items.isNotEmpty;

      Color? highlightColor;
      if (isHighlighted && items.isNotEmpty) {
        AgendaCardData? firstUncompleted;
        for (final item in items) {
          if (!item.isCompleted) {
            firstUncompleted = item;
            break;
          }
        }
        highlightColor = (firstUncompleted ?? items.first).backgroundColor;
      }

      return AgendaHourBlock(
        hour: hour,
        items: items,
        isHighlighted: isHighlighted,
        highlightColor: highlightColor,
      );
    });
  }

  AgendaCardData _mapCalendarItemToCard(
    CalendarItem item,
    CalendarController controller,
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

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.controller,
    required this.filters,
    required this.hourBlocks,
    required this.headerInfo,
    required this.scrollTrigger,
  });

  final CalendarController controller;
  final List<AgendaFilterOption> filters;
  final List<AgendaHourBlock> hourBlocks;
  final AgendaHeaderInfo headerInfo;
  final int scrollTrigger;

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
          onFilterSelected: (id) => controller.changeFilter(
            CalendarFilter.values.firstWhere(
              (filter) => filter.name == id,
              orElse: () => CalendarFilter.all,
            ),
          ),
          hourBlocks: hourBlocks,
          highlightedHour: controller.highlightedHour,
          scrollToCurrentHour: true,
          scrollTargetHour: controller.scrollTargetHour,
          scrollTrigger: scrollTrigger + controller.scrollTrigger,
          onScrollTargetConsumed: controller.clearScrollTarget,
          isLoading: controller.isLoading,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                onDayTap: (date) async {
                  final result = await Get.toNamed(
                    SelectedDayPage.route,
                    arguments: date,
                  );
                  if (result == true) {
                    controller.loadCalendarData();
                  }
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
