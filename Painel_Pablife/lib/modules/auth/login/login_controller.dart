import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/modules/coupons/panel_home.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';

class LoginController extends GetxController with LoaderManagerMixin {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    update();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite seu e-mail';
    }
    if (!GetUtils.isEmail(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite sua senha';
    }
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    changeLoading(true);

    try {
      final success = await AuthService.instance.signIn(
        emailController.text.trim(),
        passwordController.text,
      );

      if (success) {
        // Aguardar um pouco para garantir que o usuário foi carregado
        await Future.delayed(const Duration(milliseconds: 500));

        final user = AuthService.instance.currentUser;

        // Debug: verificar o que foi carregado
        if (user != null) {
          Get.log('Usuário carregado: ${user.email}');
          Get.log('Role do usuário: ${user.role}');
          Get.log('Role enum: ${user.role.value}');
          Get.log('isAdmin: ${AuthService.instance.isAdmin}');
        } else {
          Get.log('Usuário é null!');
        }

        // Admin (ou titular no painel de cupons)
        final home = user == null ? null : panelHomeRoute();
        if (home == null) {
          await AuthService.instance.signOut();
          AppSnackbar.to.error(
            'Acesso negado. Apenas administradores podem acessar o painel.',
          );
          return;
        }

        Get.offAllNamed(home);
      } else {
        AppSnackbar.to.error('E-mail ou senha incorretos');
      }
    } catch (e) {
      AppSnackbar.to.error('Erro ao fazer login: $e');
    } finally {
      changeLoading(false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (!GetUtils.isEmail(email)) {
      AppSnackbar.to.error('Informe um e-mail válido para recuperar a senha');
      return;
    }

    changeLoading(true);
    try {
      final ok = await AuthService.instance.sendPasswordResetEmail(email);
      if (ok) {
        AppSnackbar.to.success(
          'Se o e-mail estiver cadastrado, enviaremos um link de redefinição.',
        );
      } else {
        AppSnackbar.to.error(
          'Não foi possível enviar o e-mail de recuperação. Tente novamente.',
        );
      }
    } catch (e) {
      AppSnackbar.to.error('Erro ao solicitar recuperação: $e');
    } finally {
      changeLoading(false);
    }
  }
}
