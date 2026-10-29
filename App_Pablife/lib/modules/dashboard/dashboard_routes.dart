import 'package:get/get.dart';
import 'package:pablife/modules/calendar/controllers/interactive_calendar_controller.dart';
import 'package:pablife/modules/home/controllers/home_controller.dart';
import 'package:pablife/modules/profile/profile_controller.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/controllers/calendar_switcher_controller.dart';
import '../calendar/controllers/professional_calendar_controller.dart';
import '../home/controllers/professional_home_controller.dart';
import '../home/controllers/user_home_controller.dart';
import '../mentorias/mentorias_controller.dart';
import '../patients/patients_controller.dart';
import '../professionals/professionals_controller.dart';
import 'dashboard_controller.dart';
import 'dashboard_page.dart';

final dashboardRoutes = [
  GetPage(
    name: DashboardPage.route,
    page: () => const DashboardPage(),
    bindings: [
      BindingsBuilder(() {
        Get.put(DashboardController());
        Get.put(HomeController());
        Get.put(ProfessionalHomeController());
        Get.put(UserHomeController());
        Get.lazyPut(() => CalendarController(), fenix: true);
        Get.lazyPut(() => ProfessionalCalendarController(), fenix: true);
        Get.put(CalendarSwitcherController());
        Get.put(MentoriasController());
        Get.put(PatientsController());
        Get.put(ProfessionalsController());
        Get.put(ProfileController());
        Get.put(InteractiveCalendarController());
      }),
    ],
  ),
];
