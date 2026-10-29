import 'package:get/get.dart';
import 'pages/waiting_approval_page.dart';
import 'controllers/waiting_approval_controller.dart';

final waitingApprovalRoutes = [
  GetPage(
    name: WaitingApprovalPage.route,
    page: () => const WaitingApprovalPage(),
    bindings: [BindingsBuilder.put(WaitingApprovalController.new)],
  ),
];
