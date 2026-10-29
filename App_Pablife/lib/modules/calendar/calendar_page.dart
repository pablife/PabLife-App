import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/calendar_switcher_controller.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  static const route = '/calendar';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CalendarSwitcherController>(
      builder: (controller) {
        return controller.calendarPage ?? const SizedBox.shrink();
      },
    );
  }
}
