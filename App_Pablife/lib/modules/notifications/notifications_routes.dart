import 'package:get/get.dart';
import 'notifications_controller.dart';
import 'notifications_page.dart';
import '../../infra/repositories/notification_repository.dart';

final notificationsRoutes = [
  GetPage(
    name: NotificationsPage.route,
    page: () => const NotificationsPage(),
    bindings: [
      BindingsBuilder.put(NotificationRepository.new),
      BindingsBuilder.put(() => NotificationsController(Get.find())),
    ],
  ),
];

