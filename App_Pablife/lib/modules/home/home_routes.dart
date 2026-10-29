import 'package:get/get.dart';
import 'package:pablife/modules/home/controllers/home_controller.dart';
import 'home_page.dart';
import 'pages/user_home_page.dart';
import 'pages/professional_home_page.dart';
import 'controllers/user_home_controller.dart';
import 'controllers/professional_home_controller.dart';

final homeRoutes = [
  GetPage(
    name: HomePage.route,
    page: () => const HomePage(),
    bindings: [BindingsBuilder.put(HomeController.new)],
  ),
  GetPage(
    name: UserHomePage.route,
    page: () => const UserHomePage(),
    bindings: [BindingsBuilder.put(UserHomeController.new)],
  ),
  GetPage(
    name: ProfessionalHomePage.route,
    page: () => const ProfessionalHomePage(),
    bindings: [BindingsBuilder.put(ProfessionalHomeController.new)],
  ),
];
