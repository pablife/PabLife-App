import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/services/auth_service.dart';
import '../pages/email_input_page.dart';

class RecoveryPasswordCodeController extends GetxController
    with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;

  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String email = '';
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments as String? ?? '';
  }

  @override
  void onClose() {
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    update();
  }

  void toggleObscureConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
    update();
  }

  Future<void> verifyCodeAndUpdatePassword() async {
    final code = codeController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (code.isEmpty) {
      AppSnackbar.to.show('Por favor, insira o código de verificação');
      return;
    }

    if (code.length != 6) {
      AppSnackbar.to.show('O código deve ter 6 dígitos');
      return;
    }

    if (password.isEmpty) {
      AppSnackbar.to.show('Por favor, insira a nova senha');
      return;
    }

    if (password.length < 6) {
      AppSnackbar.to.show('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    if (confirmPassword.isEmpty) {
      AppSnackbar.to.show('Por favor, confirme a nova senha');
      return;
    }

    if (password != confirmPassword) {
      AppSnackbar.to.show('As senhas não coincidem');
      return;
    }

    changeLoading(true);

    try {
      final result = await _authService.verifyOtpAndUpdatePassword(
        email: email,
        token: code,
        newPassword: password,
      );

      if (result.success) {
        AppSnackbar.to.show('Senha redefinida com sucesso!');
        Get.offAllNamed(EmailInputPage.route);
      } else {
        AppSnackbar.to.show(result.error ?? 'Erro ao redefinir senha');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao redefinir senha: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  void goBack() {
    Get.back();
  }
}
