import 'package:get/get.dart';

import 'notifications_controller.dart';
import 'notifications_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class NotificationsRoutes {
  static final routes = [
    GetPage(
      name: NotificationsPage.route,
      page: () => const NotificationsPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationsController());
      }),
    ),
  ];
}
