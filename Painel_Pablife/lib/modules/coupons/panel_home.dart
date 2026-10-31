import 'package:painel_pablife/infra/services/auth_service.dart';
import 'package:painel_pablife/modules/dashboard/dashboard_page.dart';
import 'package:painel_pablife/shared/utils/app_mode.dart';

import 'coupons_overview_page.dart';
import 'titular_page.dart';

/// Tela inicial depois do login, ou null se a conta não pode entrar.
/// No painel de cupons: admin abre a visão geral e titular abre o painel
/// dele. No painel completo só admin entra.
String? panelHomeRoute() {
  final auth = AuthService.instance;
  if (auth.isAdmin) {
    return kCouponsOnly ? CouponsOverviewPage.route : DashboardPage.route;
  }
  if (kCouponsOnly && auth.isCouponOwner) return TitularPage.route;
  return null;
}
