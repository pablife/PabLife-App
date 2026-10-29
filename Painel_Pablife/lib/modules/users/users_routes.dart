import 'package:get/get.dart';
import 'users_controller.dart';
import 'users_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class UsersRoutes {
  static final routes = [
    GetPage(
      name: UsersPage.route,
      page: () => const UsersPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => UsersController());
      }),
    ),
  ];
}
