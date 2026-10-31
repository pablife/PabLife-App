import 'package:get/get.dart';
import '../../infra/services/auth_service.dart';
import '../coupons/panel_home.dart';
import '../auth/login/login_page.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Aguardar um pouco para mostrar a splash
    await Future.delayed(const Duration(seconds: 3));

    try {
      // Inicializar AuthService se não foi inicializado
      await AuthService.instance.initialize();

      // Log para debug
      Get.log(
        'SplashPage: isAuthenticated = ${AuthService.instance.isAuthenticated}',
      );
      Get.log(
        'SplashPage: currentUser = ${AuthService.instance.currentUser?.email}',
      );
      Get.log('SplashPage: isAdmin = ${AuthService.instance.isAdmin}');

      final home = panelHomeRoute();
      if (AuthService.instance.isAuthenticated && home != null) {
        // Admin (ou titular no painel de cupons): vai para a tela inicial
        Get.log('SplashPage: Redirecionando para $home');
        Get.offAllNamed(home);
      } else {
        // Não autenticado ou não é admin, ir para login
        Get.log('SplashPage: Redirecionando para login');
        await AuthService.instance.signOut();
        Get.offAllNamed(LoginPage.route);
      }
    } catch (e) {
      Get.log('SplashPage: Erro ao verificar autenticação: $e');
      Get.offAllNamed(LoginPage.route);
    }
  }
}
