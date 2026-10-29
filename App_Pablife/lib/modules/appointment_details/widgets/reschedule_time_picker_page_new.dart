import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../modules/calendar/widgets/interactive_calendar_base.dart';
import '../../../modules/calendar/widgets/calendar_month_selector_widget.dart';

class RescheduleTimePickerPage extends StatefulWidget {
  final String professionalId;

  const RescheduleTimePickerPage({super.key, required this.professionalId});

  @override
  State<RescheduleTimePickerPage> createState() =>
      _RescheduleTimePickerPageState();
}

class _RescheduleTimePickerPageState extends State<RescheduleTimePickerPage> {
  final appointmentRepository = AppointmentRepository();
  Map<String, List<ProfessionalScheduleSlot>> slotsByDate = {};
  String? expandedDateKey;
  bool isLoading = false;
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  void changeLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> _loadAvailableSlots() async {
    changeLoading(true);
    try {
      final response = await appointmentRepository.getProfessionalSlotsFromView(
        professionalId: widget.professionalId,
        date: currentMonth,
      );

      if (response.success && response.data != null) {
        final Map<String, List<ProfessionalScheduleSlot>> grouped = {};
        for (final slot in response.data!) {
          final dateKey = DateFormat('yyyy-MM-dd').format(slot.startAt);
          if (!grouped.containsKey(dateKey)) {
            grouped[dateKey] = [];
          }
          grouped[dateKey]!.add(slot);
        }
        final sortedEntries = grouped.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        setState(() {
          slotsByDate = {
            for (final entry in sortedEntries) entry.key: entry.value,
          };

          // Expande o primeiro dia com slots disponíveis
          if (slotsByDate.isNotEmpty && expandedDateKey == null) {
            expandedDateKey = slotsByDate.keys.first;
          }
        });
      }
    } finally {
      changeLoading(false);
    }
  }

  void _onSlotSelected(CalendarSlotData slot) {
    Get.back(result: slot.id);
  }

  void _onExpandedChanged(String? dateKey) {
    setState(() {
      expandedDateKey = dateKey;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + delta, 1);
      expandedDateKey = null;
    });
    _loadAvailableSlots();
  }

  List<CalendarDayData> _buildCalendarDays() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    final totalDays = nextMonth.difference(firstDay).inDays;

    return List.generate(totalDays, (index) {
      final date = DateTime(currentMonth.year, currentMonth.month, index + 1);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final slots = slotsByDate[dateKey] ?? <ProfessionalScheduleSlot>[];

      return CalendarDayData(
        date: date,
        slots: slots
            .map(
              (slot) => CalendarSlotData(
                id: slot.id,
                startAt: slot.startAt,
                finishAt: slot.finishAt,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF001417),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC1CDFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF001417),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CalendarMonthSelectorWidget(
                      currentMonth: currentMonth,
                      onChangeMonth: _changeMonth,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveCalendarBase(
                days: _buildCalendarDays(),
                displayMode: CalendarDisplayMode.slots,
                expandedDateKey: expandedDateKey,
                onExpandedChanged: _onExpandedChanged,
                onSlotTap: _onSlotSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
