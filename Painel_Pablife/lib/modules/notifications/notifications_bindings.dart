import 'package:get/get.dart';
import './notifications_controller.dart';

class NotificationsBindings implements Bindings {
    @override
    void dependencies() {
        Get.put(NotificationsController());
    }
}