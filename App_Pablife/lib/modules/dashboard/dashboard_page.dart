import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/user_role.dart';
import 'package:pablife/infra/services/auth_service.dart';
import 'package:pablife/modules/dashboard/widgets/dashboard_navbar.dart';
import 'package:pablife/modules/dashboard/widgets/dashboard_side_menu.dart';
import 'package:pablife/modules/home/home_page.dart';
import 'package:pablife/modules/calendar/calendar_page.dart';
import 'package:pablife/modules/mentorias/mentorias_page.dart';
import 'package:pablife/modules/patients/patients_page.dart';
import 'package:pablife/modules/professionals/professionals_page.dart';
import 'package:pablife/modules/profile/profile_page.dart';
import 'package:pablife/shared/utils/wide_layout.dart';
import 'dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const route = '/dashboard';

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final isProfessional =
        authService.currentUser?.role == UserRole.professional;

    final List<Widget> pages = [
      const HomePage(),
      const CalendarPage(),
      const MentoriasPage(),
      isProfessional ? const PatientsPage() : const ProfessionalsPage(),
      const ProfilePage(),
    ];

    return GetBuilder<DashboardController>(
      builder: (controller) {
        if (isWideLayout(context)) {
          return Scaffold(
            body: Row(
              children: [
                DashboardSideMenu(
                  controller: controller,
                  isProfessional: isProfessional,
                ),
                Expanded(
                  // O Dashboard e os Profissionais do usuário e a Agenda do
                  // profissional têm layout próprio em colunas; as outras
                  // abas ficam numa coluna centralizada.
                  child: switch (controller.currentIndex) {
                    0 when !isProfessional => pages[0],
                    3 when !isProfessional => WideCenter(
                      maxWidth: 1400,
                      child: pages[3],
                    ),
                    1 when isProfessional => WideCenter(
                      maxWidth: 1600,
                      child: pages[1],
                    ),
                    final index => WideCenter(child: pages[index]),
                  },
                ),
              ],
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          body: pages[controller.currentIndex],
          bottomNavigationBar: DashboardNavbar(controller: controller),
        );
      },
    );
  }
}
