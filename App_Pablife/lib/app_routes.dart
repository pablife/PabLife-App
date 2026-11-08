import 'package:get/get.dart';
import 'modules/auth/pages/choose_profile_page.dart';
import 'modules/auth/pages/email_input_page.dart';
import 'modules/auth/pages/password_page.dart';
import 'modules/auth/pages/recovery_password_code_page.dart';
import 'modules/auth/pages/recovery_password_page.dart';
import 'modules/auth/pages/visual_choice_page.dart';
import 'modules/dashboard/dashboard_page.dart';
import 'modules/onboarding/onboarding_page.dart';
import 'shared/utils/wide_layout.dart';
import 'modules/splash/splash_routes.dart';
import 'modules/auth/auth_routes.dart';
import 'modules/onboarding/onboarding_routes.dart';
import 'modules/home/home_routes.dart';
import 'modules/dashboard/dashboard_routes.dart';
import 'modules/waiting_approval/waiting_approval_routes.dart';
import 'modules/calendar/calendar_routes.dart';
import 'modules/mentorias/mentorias_routes.dart';
import 'modules/professionals/booking/booking_page.dart';
import 'modules/professionals/professionals_routes.dart';
import 'modules/profile/profile_routes.dart';
import 'modules/notifications/notifications_routes.dart';
import 'modules/appointment_details/appointment_details_routes.dart';

class AppRoutes {
  AppRoutes._();

  /// Telas que ocupam a largura toda no computador: o Dashboard (menu lateral)
  /// e as telas de entrada, com fundo de ponta a ponta.
  static const _fullWidthRoutes = {
    DashboardPage.route,
    OnboardingPage.route,
    ChooseProfilePage.route,
    VisualChoicePage.route,
    EmailInputPage.route,
    PasswordPage.route,
    RecoveryPasswordPage.route,
    RecoveryPasswordCodePage.route,
    BookingPage.route,
  };

  /// No computador, as telas desenhadas para celular abrem numa coluna
  /// centralizada.
  static List<GetPage> pages = _allPages
      .map(
        (page) => _fullWidthRoutes.contains(page.name)
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
