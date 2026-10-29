import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../../modules/auth/login/login_page.dart';

/// Middleware para proteger rotas que exigem autenticação/admin.
class AuthGuard extends GetMiddleware {
  AuthGuard();

  @override
  RouteSettings? redirect(String? route) {
    final isAuthenticated = AuthService.instance.isAuthenticated;
    final isAdmin = AuthService.instance.isAdmin;

    if (!isAuthenticated || !isAdmin) {
      // Redireciona para login quando não autenticado ou sem permissão.
      return const RouteSettings(name: LoginPage.route);
    }

    return null;
  }
}
