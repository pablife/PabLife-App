import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/infra/repositories/coupon_repository.dart';
import 'package:painel_pablife/infra/services/auth_service.dart';
import 'package:painel_pablife/modules/auth/login/login_page.dart';

import '../../infra/middlewares/auth_guard.dart';
import 'coupon_consultations_page.dart';
import 'coupon_owner_detail_page.dart';
import 'coupon_owners_page.dart';
import 'coupons_controller.dart';
import 'coupons_overview_page.dart';
import 'coupons_page.dart';
import 'titular_page.dart';

class CouponsRoutes {
  CouponsRoutes._();

  // Um só controller para todas as abas de cupons do admin.
  static final _adminBinding = BindingsBuilder(() {
    Get.lazyPut(() => CouponRepository(), fenix: true);
    Get.lazyPut(
      () => CouponsController(Get.find<CouponRepository>()),
      fenix: true,
    );
  });

  static GetPage _admin(String name, Widget Function() page) => GetPage(
    name: name,
    page: page,
    middlewares: [AuthGuard()],
    binding: _adminBinding,
  );

  static List<GetPage> get routes => [
    _admin(CouponsOverviewPage.route, () => const CouponsOverviewPage()),
    _admin(CouponsPage.route, () => const CouponsPage()),
    _admin(CouponOwnersPage.route, () => const CouponOwnersPage()),
    _admin(CouponOwnerDetailPage.route, () => const CouponOwnerDetailPage()),
    _admin(
      CouponConsultationsPage.route,
      () => const CouponConsultationsPage(),
    ),
    GetPage(
      name: TitularPage.route,
      page: () => const TitularPage(),
      middlewares: [TitularGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CouponRepository(), fenix: true);
        Get.lazyPut(() => TitularController(Get.find<CouponRepository>()));
      }),
    ),
  ];
}

/// Rota do titular: precisa estar logado e ligado a um titular.
class TitularGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated || !auth.isCouponOwner) {
      return const RouteSettings(name: LoginPage.route);
    }
    return null;
  }
}
