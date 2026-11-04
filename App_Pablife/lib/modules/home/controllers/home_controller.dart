import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/user_role.dart';
import '../../../infra/services/auth_service.dart';
import '../pages/professional_home_page.dart';
import '../pages/user_home_page.dart';

class HomeController extends GetxController {
  final AuthService authService = AuthService.instance;

  /// Segue o lado ativo: a mesma conta pode entrar como profissional ou usuário.
  Widget get homePage => authService.currentUser?.role == UserRole.professional
      ? const ProfessionalHomePage()
      : const UserHomePage();
}
