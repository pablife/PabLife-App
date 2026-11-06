import 'package:get/get.dart';
import 'professionals_controller.dart';
import 'professionals_page.dart';
import 'details/professional_details_controller.dart';
import 'details/professional_details_page.dart';
import 'booking/booking_controller.dart';
import 'booking/booking_page.dart';
import '../../infra/models/professional_with_user_model.dart';

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
    name: BookingPage.route,
    page: () => const BookingPage(),
    bindings: [
      BindingsBuilder(() {
        Get.put(
          BookingController.live(Get.arguments as ProfessionalWithUserModel),
        );
      }),
    ],
  ),
];
