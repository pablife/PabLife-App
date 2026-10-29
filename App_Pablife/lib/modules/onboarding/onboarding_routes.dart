import 'package:get/get.dart';
import 'onboarding_page.dart';
import 'onboarding_controller.dart';

final onboardingRoutes = [
  GetPage(
    name: OnboardingPage.route,
    page: () => const OnboardingPage(),
    bindings: [BindingsBuilder.put(OnboardingController.new)],
  ),
];
