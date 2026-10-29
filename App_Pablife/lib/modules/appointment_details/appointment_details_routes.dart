import 'package:get/get.dart';

import 'appointment_details_controller.dart';
import 'appointment_details_page.dart';
import 'record_editor/record_editor_controller.dart';
import 'record_editor/record_editor_page.dart';

abstract class AppointmentDetailsRoutes {
  static const appointmentDetails = '/appointment-details';

  static final routes = [
    GetPage(
      name: appointmentDetails,
      page: () => const AppointmentDetailsPage(),
      bindings: [BindingsBuilder.put(AppointmentDetailsController.new)],
    ),
    GetPage(
      name: RecordEditorPage.route,
      page: () => const RecordEditorPage(),
      bindings: [BindingsBuilder.put(RecordEditorController.new)],
    ),
  ];
}
