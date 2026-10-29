import 'package:get/get.dart';
import 'package:painel_pablife/infra/services/auth_service.dart';

class UserHelper {
  UserHelper._();

  static UserHelper get instance => UserHelper._();

  Future<void> logout() async {
    await AuthService.instance.signOut();
    Get.offAllNamed('/login');
  }
}
