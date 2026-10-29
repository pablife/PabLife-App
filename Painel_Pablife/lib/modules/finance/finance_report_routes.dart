import 'package:get/get.dart';
import 'finance_report_controller.dart';
import 'finance_report_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class FinanceReportRoutes {
  static final routes = [
    GetPage(
      name: FinanceReportPage.route,
      page: () => const FinanceReportPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceReportController());
      }),
    ),
  ];
}
