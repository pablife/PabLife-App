import 'package:get/get.dart';
import 'package:painel_pablife/infra/repositories/mentorship_repository.dart';
import 'infra/repositories/user_repository.dart';
import 'infra/repositories/professional_repository.dart';
import 'infra/repositories/appointment_repository.dart';
import 'infra/repositories/subscription_repository.dart';
import 'modules/splash/splash_page.dart';
import 'modules/splash/splash_controller.dart';
import 'modules/auth/login/login_controller.dart';
import 'modules/auth/login/login_page.dart';
import 'modules/public/privacy_policy_page.dart';
import 'modules/dashboard/dashboard_controller.dart';
import 'modules/dashboard/dashboard_page.dart';
import 'modules/users/users_page.dart';
import 'modules/users/users_controller.dart';
import 'modules/professionals/professionals_page.dart';
import 'modules/professionals/professionals_controller.dart';
import 'modules/professionals/professionals_pending_page.dart';
import 'modules/professionals/professional_approval_page.dart';
import 'modules/mentorship/mentorship_routes.dart';
import 'modules/appointments/appointments_routes.dart';
import 'modules/finance/finance_report_page.dart';
import 'modules/finance/finance_report_controller.dart';
import 'modules/banners/banners_routes.dart';
import 'modules/coupons/coupons_routes.dart';
import 'modules/notifications/notifications_routes.dart';
import 'modules/subscriptions/cancelled_subscriptions_page.dart';
import 'modules/subscriptions/cancelled_subscriptions_controller.dart';
import 'infra/middlewares/auth_guard.dart';

class AppRoutes {
  AppRoutes._();

  static List<GetPage> get routes => [
    // Splash
    GetPage(
      name: SplashPage.route,
      page: () => const SplashPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SplashController());
      }),
    ),

    // Auth
    GetPage(
      name: LoginPage.route,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),

    // Dashboard
    GetPage(
      name: DashboardPage.route,
      page: () => const DashboardPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        // Injetar repositórios
        Get.lazyPut(() => UserRepository());
        Get.lazyPut(() => ProfessionalRepository());
        Get.lazyPut(() => AppointmentRepository());
        Get.lazyPut(() => MentorshipRepository());
        Get.lazyPut(() => SubscriptionRepository());

        // Injetar controller com dependências
        Get.lazyPut(
          () => DashboardController(
            Get.find<UserRepository>(),
            Get.find<ProfessionalRepository>(),
            Get.find<AppointmentRepository>(),
            Get.find<MentorshipRepository>(),
            Get.find<SubscriptionRepository>(),
          ),
        );
      }),
    ),

    // Users
    GetPage(
      name: UsersPage.route,
      page: () => const UsersPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => UsersController());
      }),
    ),

    // Professionals
    GetPage(
      name: ProfessionalsPage.route,
      page: () => const ProfessionalsPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfessionalsController());
      }),
    ),

    // Professionals Pending Approval (old route)
    GetPage(
      name: ProfessionalsPendingPage.route,
      page: () => const ProfessionalsPendingPage(),
      middlewares: [AuthGuard()],
    ),

    // Professional Approval
    GetPage(
      name: ProfessionalApprovalPage.route,
      page: () => const ProfessionalApprovalPage(),
      middlewares: [AuthGuard()],
    ),

    // Mentorship - rotas separadas no módulo
    ...MentorshipRoutes.routes,

    // Appointments - rotas separadas no módulo
    ...AppointmentsRoutes.routes,

    // Finance Report
    GetPage(
      name: FinanceReportPage.route,
      page: () => const FinanceReportPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceReportController());
      }),
    ),

    // Banners - rotas separadas no módulo
    ...BannersRoutes.routes,

    // Cupons - rotas separadas no módulo
    ...CouponsRoutes.routes,

    // Notifications - rotas separadas no módulo
    ...NotificationsRoutes.routes,

    // Cancelled Subscriptions
    GetPage(
      name: CancelledSubscriptionsPage.route,
      page: () => const CancelledSubscriptionsPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CancelledSubscriptionsController());
      }),
    ),

    // Paginas Publicas (acessiveis sem autenticacao)
    GetPage(
      name: PrivacyPolicyPage.route,
      page: () => const PrivacyPolicyPage(),
    ),
  ];
}
