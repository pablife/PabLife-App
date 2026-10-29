import 'package:get/get.dart';
import 'professionals_controller.dart';
import 'professionals_page.dart';
import 'details/professional_details_controller.dart';
import 'details/professional_details_page.dart';
import 'pages/appointment_success_page.dart';

final professionalsRoutes = [
  GetPage(
    name: ProfessionalsPage.route,
    page: () => const ProfessionalsPage(),
    bindings: [BindingsBuilder.put(ProfessionalsController.new)],
  ),
  GetPage(
    name: ProfessionalDetailsPage.route,
    page: () => const ProfessionalDetailsPage(),
    bindings: [BindingsBuilder.put(ProfessionalDetailsController.new)],
  ),
  GetPage(
    name: AppointmentSuccessPage.route,
    page: () => const AppointmentSuccessPage(),
  ),
];
