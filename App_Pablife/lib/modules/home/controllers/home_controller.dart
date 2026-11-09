import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/user_role.dart';
import '../../../infra/services/auth_service.dart';
import '../../professional_area/professional_dashboard_page.dart';
import '../pages/user_home_page.dart';

class HomeController extends GetxController {
  final AuthService authService = AuthService.instance;

  /// Segue o lado ativo: a mesma conta pode entrar como profissional ou usuário.
  Widget get homePage => authService.currentUser?.role == UserRole.professional
      ? const ProfessionalDashboardPage()
      : const UserHomePage();
}
