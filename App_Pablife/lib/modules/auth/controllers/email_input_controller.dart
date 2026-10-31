import 'package:get/get.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/repositories/user_repository.dart';

class EmailInputController extends GetxController with LoaderManagerMixin {
  final UserRepository _userRepository = UserRepository();

  String email = '';

  void updateEmail(String value) {
    email = value;
    update();
  }

  Future<void> checkEmail() async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      AppSnackbar.to.show('Por favor, insira seu email');
      return;
    }

    if (!_isValidEmail(normalizedEmail)) {
      AppSnackbar.to.show('Por favor, insira um email válido');
      return;
    }

    changeLoading(true);

    try {
      final response = await _userRepository.validateEmail(normalizedEmail);

      if (!response.success) {
        AppSnackbar.to.show(
          response.message.isNotEmpty
              ? response.message
              : 'Erro ao verificar email',
        );
        return;
      }

      final exists =
          response.data == true || response.data?.toString() == 'true';

      if (exists) {
        Get.toNamed('/auth/password', arguments: normalizedEmail);
      } else {
        Get.toNamed('/auth/signup', arguments: normalizedEmail);
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao verificar email: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  bool _isValidEmail(String email) {
    // Aceita "+" e outros caracteres válidos (ex.: nome+teste@gmail.com).
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
}
