import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../infra/models/user_role.dart';
import '../../infra/services/auth_service.dart';
import '../auth/entry_visual.dart';
import '../home/controllers/user_home_controller.dart';
import '../profile/profile_controller.dart';
import '../../shared/mixins/loader_manager.dart';
import '../professional_area/professional_area_controller.dart';

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

  @override
  void onReady() {
    super.onReady();
    // Questionário da Saúde da Mulher (conta nova) ou o aviso único.
    EntryVisual.onDashboardReady();
  }

  void changeTab(int index) {
    currentIndex = index;
    update();

    if (index == 0) {
      final role = AuthService.instance.currentUser?.role;
      if (role == UserRole.professional) {
        if (Get.isRegistered<ProfessionalAreaController>()) {
          Get.find<ProfessionalAreaController>().load();
        }
      } else {
        if (Get.isRegistered<UserHomeController>()) {
          Get.find<UserHomeController>().refreshDataSilent();
        }
      }
    }

    if (index == 2 &&
        AuthService.instance.currentUser?.role == UserRole.professional &&
        Get.isRegistered<ProfessionalAreaController>()) {
      Get.find<ProfessionalAreaController>().load();
    }

    if (index == 4 && Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().reloadProfile();
    }
  }
}
