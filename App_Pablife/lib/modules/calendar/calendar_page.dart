import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/user_role.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/utils/wide_layout.dart';
import 'controllers/calendar_switcher_controller.dart';
import 'pages/professional_wide_calendar_page.dart';
import 'pages/user_wide_calendar_page.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  static const route = '/calendar';

  @override
  Widget build(BuildContext context) {
    // Usuário: a agenda nova (dia/semana/mês/ano) no computador e no celular.
    // Profissional: a agenda nova só no computador.
    final isProfessional =
        AuthService.instance.currentUser?.role == UserRole.professional;
    if (!isProfessional) return const UserWideCalendarPage();
    if (isWideLayout(context)) return const ProfessionalWideCalendarPage();

    return GetBuilder<CalendarSwitcherController>(
      builder: (controller) {
        return controller.calendarPage;
      },
    );
  }
}
