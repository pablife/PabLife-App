import 'package:get/get.dart';
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

  static List<GetPage> pages = [
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
