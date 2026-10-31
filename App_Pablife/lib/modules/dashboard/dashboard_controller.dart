import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../infra/models/user_role.dart';
import '../../infra/services/auth_service.dart';
import '../home/controllers/professional_home_controller.dart';
import '../home/controllers/user_home_controller.dart';
import '../profile/profile_controller.dart';
import '../../shared/mixins/loader_manager.dart';

class DashboardController extends GetxController with LoaderManagerMixin {
  static DashboardController get to => Get.find();

  int currentIndex = 0;

  @override
  void onInit() {
    super.onInit();
    // Na web, quem não é profissional já entra vendo os profissionais.
    final role = AuthService.instance.currentUser?.role;
    if (kIsWeb && role != UserRole.professional) {
      currentIndex = 3;
    }
  }

  void changeTab(int index) {
    currentIndex = index;
    update();

    if (index == 0) {
      final role = AuthService.instance.currentUser?.role;
      if (role == UserRole.professional) {
        if (Get.isRegistered<ProfessionalHomeController>()) {
          Get.find<ProfessionalHomeController>().refreshDataSilent();
        }
      } else {
        if (Get.isRegistered<UserHomeController>()) {
          Get.find<UserHomeController>().refreshDataSilent();
        }
      }
    }

    if (index == 4 && Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().reloadProfile();
    }
  }
}
