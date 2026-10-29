import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../infra/models/user_role.dart';
import '../../../infra/services/auth_service.dart';
import '../pages/professional_calendar_tab_page.dart';
import '../pages/calendar_tab_page.dart';

class CalendarSwitcherController extends GetxController {
  final AuthService _authService = AuthService.instance;

  Widget? calendarPage;

  @override
  void onInit() {
    super.onInit();
    _initializePage();
  }

  void _initializePage() {
    final currentUser = _authService.currentUser;
    calendarPage = currentUser?.role == UserRole.professional
        ? const ProfessionalCalendarTabPage()
        : const CalendarTabPage();
  }
}
