import 'package:get/get.dart';
import '../../infra/services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
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

      if (AuthService.instance.isAuthenticated &&
          AuthService.instance.isAdmin) {
        // Usuário autenticado e é admin, ir para dashboard
        Get.log('SplashPage: Redirecionando para dashboard');
        Get.offAllNamed(DashboardPage.route);
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
