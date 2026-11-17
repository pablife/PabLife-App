import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Toda abertura do app passa pela Splash, que confere o login e leva cada
/// pessoa para o lugar certo.
///
/// Na web o navegador guarda o endereço da última tela (ex.: o cadastro). Sem
/// esta guarda, abrir o site nesse endereço pulava a Splash e mostrava o
/// cadastro de novo para quem já tem conta.
class StartupGuard extends GetMiddleware {
  StartupGuard(this.splashRoute);

  final String splashRoute;

  /// Vira true quando a Splash começa a conferir o login.
  static bool passedSplash = false;

  @override
  RouteSettings? redirect(String? route) {
    if (passedSplash || route == splashRoute) return null;
    return RouteSettings(name: splashRoute);
  }
}
