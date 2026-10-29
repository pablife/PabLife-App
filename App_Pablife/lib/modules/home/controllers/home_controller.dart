import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/user_role.dart';
import '../../../infra/services/auth_service.dart';
import '../pages/professional_home_page.dart';
import '../pages/user_home_page.dart';

class HomeController extends GetxController {
  final AuthService authService = AuthService.instance;
  Widget? homePage;

  @override
  void onInit() {
    super.onInit();
    if (authService.currentUser?.role == UserRole.professional) {
      homePage = const ProfessionalHomePage();
    } else {
      homePage = const UserHomePage();
    }
  }
}
