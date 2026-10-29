import 'package:get/get.dart';
import 'package:painel_pablife/infra/repositories/banner_repository.dart';
import 'package:painel_pablife/modules/banners/banners_controller.dart';
import 'package:painel_pablife/modules/banners/banners_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class BannersRoutes {
  BannersRoutes._();

  static List<GetPage> get routes => [
    GetPage(
      name: BannersPage.route,
      page: () => const BannersPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => BannerRepository());
        Get.lazyPut(() => BannersController(Get.find<BannerRepository>()));
      }),
    ),
  ];
}
