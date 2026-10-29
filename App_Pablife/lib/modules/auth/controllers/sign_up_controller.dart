import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:pablife/modules/auth/pages/professional_profile_page.dart';
import 'package:pablife/modules/splash/splash_page.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/user_role.dart';
import '../../../infra/models/user_status.dart';

class SignUpController extends GetxController with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;

  String email = '';
  String password = '';
  String fullName = '';
  String phone = '';
  String cpfDocument = '';
  String accountType = 'cliente';
  bool termsAccepted = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();

  @override
  void onClose() {
    phoneController.dispose();
    cpfController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments as String? ?? '';
  }

  void updateFullName(String value) {
    fullName = value;
    update();
  }

  void updateEmail(String value) {
    email = value;
    update();
  }

  void updatePhone(String value) {
    phone = UtilBrasilFields.removeCaracteres(value);
  }

  void updateCpfDocument(String value) {
    cpfDocument = UtilBrasilFields.removeCaracteres(value);
  }

  void updatePassword(String value) {
    password = value;
    update();
  }

  void updateAccountType(String value) {
    accountType = value;
    update();
  }

  void updateTermsAccepted(bool value) {
    termsAccepted = value;
    update();
  }

  Future<void> signUp() async {
    if (!_validateForm()) return;

    if (accountType == 'profissional') {
      Get.toNamed(
        ProfessionalProfilePage.route,
        arguments: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'cpfDocument': cpfDocument,
        },
      );
    } else {
      changeLoading(true);

      try {
        final userData = UserModel(
          fullName: fullName,
          email: email,
          phone: phone,
          cpfDocument: cpfDocument,
          termsAccepted: termsAccepted,
          role: UserRole.user,
          status: UserStatus.active,
          professionalType: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await _authService.signUpWithEmail(
          email,
          password,
          userData,
        );

        if (success) {
          Get.offAllNamed(SplashPage.route);
        } else {
          final errorMessage =
              _authService.lastSignUpError ??
              'Erro ao criar conta. Tente novamente.';
          AppSnackbar.to.show(errorMessage);
        }
      } catch (e) {
        AppSnackbar.to.show('Erro ao criar conta: ${e.toString()}');
      } finally {
        changeLoading(false);
      }
    }
  }

  bool _validateForm() {
    if (fullName.isEmpty) {
      AppSnackbar.to.show('Por favor, insira seu nome completo');
      return false;
    }

    if (phone.isEmpty) {
      AppSnackbar.to.show('Por favor, insira seu telefone');
      return false;
    }

    if (cpfDocument.isEmpty) {
      AppSnackbar.to.show('Por favor, insira seu CPF');
      return false;
    }

    if (password.isEmpty) {
      AppSnackbar.to.show('Por favor, insira uma senha');
      return false;
    }

    if (password.length < 6) {
      AppSnackbar.to.show('A senha deve ter pelo menos 6 caracteres');
      return false;
    }

    if (!termsAccepted) {
      AppSnackbar.to.show('Você deve aceitar os termos de uso');
      return false;
    }

    return true;
  }
}
