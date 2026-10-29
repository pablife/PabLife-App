import 'package:get/get.dart';
import '../../infra/repositories/subscription_repository.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';

class CancelledSubscriptionsController extends GetxController
    with LoaderManagerMixin {
  final SubscriptionRepository _repository = SubscriptionRepository();

  List<Map<String, dynamic>> users = [];

  @override
  void onInit() {
    super.onInit();
    loadCancelledUsers();
  }

  Future<void> loadCancelledUsers() async {
    changeLoading(true);

    final response = await _repository.getUsersWithCancelledSubscriptions();

    if (response.success) {
      users = response.data ?? [];
    } else {
      AppSnackbar.to.error(
        'Erro ao carregar usuários com assinaturas canceladas',
      );
    }

    changeLoading(false);
    update();
  }
}
