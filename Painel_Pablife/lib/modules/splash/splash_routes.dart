import 'package:get/get.dart';
import 'splash_controller.dart';
import 'splash_page.dart';

class SplashRoutes {
  static final routes = [
    GetPage(
      name: SplashPage.route,
      page: () => const SplashPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SplashController());
      }),
    ),
  ];
}
