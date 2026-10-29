import 'package:get/get.dart';
import 'splash_page.dart';
import 'splash_controller.dart';

final splashRoutes = [
  GetPage(
    name: SplashPage.route,
    page: () => const SplashPage(),
    bindings: [BindingsBuilder.put(SplashController.new)],
  ),
];
