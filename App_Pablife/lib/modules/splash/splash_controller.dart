import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pablife/modules/dashboard/dashboard_page.dart';
import 'package:pablife/modules/update_availability/update_availability_page.dart';
import 'package:pablife/modules/waiting_approval/pages/waiting_approval_page.dart';
import 'package:update_available/update_available.dart';

import '../../infra/models/user_role.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/repositories/user_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/mixins/loader_manager.dart';
import '../onboarding/onboarding_page.dart';

class SplashController extends GetxController with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final UserRepository _userRepository = UserRepository();

  @override
  void onReady() {
    super.onReady();
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    changeLoading(true);

    final updateAvailability = await getUpdateAvailability();
    if (updateAvailability == UpdateAvailable()) {
      Get.offAll(UpdateAvailabilityPage());
      return;
    }

    await AuthService.instance.initialize();

    final oneSignalUserId = OneSignal.User.pushSubscription.id;
    if (oneSignalUserId != null) {
      await _userRepository.setOneSignalUserId(oneSignalUserId);
    } else {
      await _userRepository.setOneSignalUserId('');
    }

    if (_authService.isAuthenticated) {
      final user = _authService.currentUser;
      if (user != null) {
        debugPrint('user role: ${user.role}');
        if (user.role == UserRole.professional) {
          final professionalResponse = await _professionalRepository
              .getProfessionalByUserId(user.id!);

          if (professionalResponse.success &&
              professionalResponse.data != null) {
            final validationStatus =
                professionalResponse.data!.validationStatus;

            if (validationStatus != 'approved') {
              Get.offAllNamed(WaitingApprovalPage.route);
              changeLoading(false);
              return;
            }
          }
        }

        Get.offAllNamed(DashboardPage.route);
      } else {
        Get.offAllNamed(OnboardingPage.route);
      }
    } else {
      Get.offAllNamed(OnboardingPage.route);
    }

    changeLoading(false);
  }
}
