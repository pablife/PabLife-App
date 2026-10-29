import 'package:get/get.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/services/auth_service.dart';
import '../pages/recovery_password_code_page.dart';

class RecoveryPasswordController extends GetxController
    with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;

  String email = '';

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments as String? ?? '';
  }

  void updateEmail(String value) {
    email = value;
    update();
  }

  Future<void> sendRecoveryLink() async {
    if (email.isEmpty) {
      AppSnackbar.to.show('Por favor, insira seu e-mail');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      AppSnackbar.to.show('Por favor, insira um e-mail válido');
      return;
    }

    changeLoading(true);

    try {
      final success = await _authService.resetPassword(email);

      if (success) {
        AppSnackbar.to.show('Código enviado! Verifique seu e-mail.');
        Get.toNamed(RecoveryPasswordCodePage.route, arguments: email);
      } else {
        AppSnackbar.to.show('Erro ao enviar código de recuperação');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao enviar código: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  void goToLogin() {
    Get.back();
  }
}
