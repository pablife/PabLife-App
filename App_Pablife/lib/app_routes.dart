import 'package:get/get.dart';
import 'modules/dashboard/dashboard_page.dart';
import 'shared/utils/wide_layout.dart';
import 'modules/splash/splash_routes.dart';
import 'modules/auth/auth_routes.dart';
import 'modules/onboarding/onboarding_routes.dart';
import 'modules/home/home_routes.dart';
import 'modules/dashboard/dashboard_routes.dart';
import 'modules/waiting_approval/waiting_approval_routes.dart';
import 'modules/calendar/calendar_routes.dart';
import 'modules/mentorias/mentorias_routes.dart';
import 'modules/professionals/professionals_routes.dart';
import 'modules/profile/profile_routes.dart';
import 'modules/notifications/notifications_routes.dart';
import 'modules/appointment_details/appointment_details_routes.dart';

class AppRoutes {
  AppRoutes._();

  /// No computador, as telas desenhadas para celular abrem numa coluna
  /// centralizada; só o Dashboard ocupa a largura toda (menu lateral).
  static List<GetPage> pages = _allPages
      .map(
        (page) => page.name == DashboardPage.route
            ? page
            : page.copy(
                page: () => WideCenter(maxWidth: 760, child: page.page()),
              ),
      )
      .toList();

  static final List<GetPage> _allPages = [
    ...splashRoutes,
    ...authRoutes,
    ...onboardingRoutes,
    ...homeRoutes,
    ...dashboardRoutes,
    ...waitingApprovalRoutes,
    ...calendarRoutes,
    ...mentoriasRoutes,
    ...professionalsRoutes,
    ...profileRoutes,
    ...notificationsRoutes,
    ...AppointmentDetailsRoutes.routes,
  ];
}
