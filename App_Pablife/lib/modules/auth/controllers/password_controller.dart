import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pablife/modules/auth/pages/recovery_password_page.dart';
import 'package:pablife/modules/dashboard/dashboard_page.dart';
import '../../../infra/repositories/user_repository.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/services/auth_service.dart';

class PasswordController extends GetxController with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;
  final UserRepository _userRepository = UserRepository();

  String email = '';
  String password = '';

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments as String? ?? '';
  }

  void updatePassword(String value) {
    password = value;
    update();
  }

  Future<void> signIn() async {
    if (password.isEmpty) {
      AppSnackbar.to.show('Por favor, insira sua senha');
      return;
    }

    if (password.length < 6) {
      AppSnackbar.to.show('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    changeLoading(true);

    try {
      final success = await _authService.signInWithEmail(email, password);

      if (success) {
        // OneSignal não tem suporte na web.
        if (!kIsWeb) {
          final oneSignalUserId = OneSignal.User.pushSubscription.id;
          if (oneSignalUserId != null) {
            await _userRepository.setOneSignalUserId(oneSignalUserId);
          } else {
            await _userRepository.setOneSignalUserId('');
          }
        }
        Get.offAllNamed(DashboardPage.route);
      } else {
        AppSnackbar.to.show('Email ou senha incorretos');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao fazer login: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  void forgotPassword() {
    Get.toNamed(RecoveryPasswordPage.route, arguments: email);
  }
}
