import 'package:get/get.dart';
import 'package:painel_pablife/modules/auth/login/login_page.dart';
import 'infra/services/auth_service.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await AuthService.instance.initialize();
  }

  Future<void> logout() async {
    await AuthService.instance.signOut();
    Get.offAllNamed(LoginPage.route);
  }
}
