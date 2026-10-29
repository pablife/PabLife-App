import 'package:get/get.dart';
import 'appointments_controller.dart';
import 'appointments_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class AppointmentsRoutes {
  static final routes = [
    GetPage(
      name: AppointmentsPage.route,
      page: () => const AppointmentsPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut<AppointmentsController>(() => AppointmentsController());
      }),
    ),
  ];
}
