import 'package:get/get.dart';
import 'package:painel_pablife/infra/repositories/mentorship_repository.dart';
import '../../../infra/repositories/user_repository.dart';
import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/repositories/subscription_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';

class DashboardController extends GetxController with LoaderManagerMixin {
  final UserRepository _userRepository;
  final ProfessionalRepository _professionalRepository;
  final AppointmentRepository _appointmentRepository;
  final MentorshipRepository _mentorshipRepository;
  final SubscriptionRepository _subscriptionRepository;

  DashboardController(
    this._userRepository,
    this._professionalRepository,
    this._appointmentRepository,
    this._mentorshipRepository,
    this._subscriptionRepository,
  );

  // Estatísticas
  int totalUsers = 0;
  int totalProfessionals = 0;
  int totalAppointments = 0;
  int pendingApprovals = 0;
  int totalMentorship = 0;

  // Novas estatísticas de assinaturas
  int cancelledSubscriptions = 0;
  Map<String, int> subscriptionsByPlan = {};

  // Estatísticas detalhadas
  Map<String, int> professionalStats = {};
  Map<String, int> professionalsByType = {};
  Map<String, int> appointmentStats = {};

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    changeLoading(true);
    try {
      // Buscar dados reais
      final totalUsersRes = await _userRepository.getTotalUsers();
      final proStatsRes = await _professionalRepository.countByStatus();
      final proTypeRes = await _professionalRepository.countByType();
      final totalApptsRes = await _appointmentRepository.getTotalAppointments();
      final totalMentRes = await _mentorshipRepository.getTotalMentorship();

      // Buscar dados de assinaturas
      final cancelledSubsRes = await _subscriptionRepository
          .getCancelledSubscriptionsCount();
      final subsByPlanRes = await _subscriptionRepository
          .getAllSubscriptionsByPlan(); // Mudado para pegar todos os planos

      totalUsers = totalUsersRes.data ?? 0;
      professionalStats = proStatsRes.data ?? {};
      professionalsByType = proTypeRes.data ?? {};
      totalAppointments = totalApptsRes.data ?? 0;
      totalMentorship = totalMentRes.data ?? 0;

      cancelledSubscriptions = cancelledSubsRes.data ?? 0;

      final planData = subsByPlanRes.data ?? {};
      subscriptionsByPlan = planData.map((key, value) {
        int count = 0;
        if (value is int) {
          count = value;
        } else if (value is String) {
          count = int.tryParse(value) ?? 0;
        } else if (value is double) {
          count = value.toInt();
        }
        return MapEntry(key, count);
      });

      totalProfessionals =
          (professionalStats['pending'] ?? 0) +
          (professionalStats['approved'] ?? 0);
      pendingApprovals = professionalStats['pending'] ?? 0;

      update();
    } catch (e) {
      AppSnackbar.to.error('Erro ao carregar dados do dashboard');
      // TODO: Implementar logging adequado
    } finally {
      changeLoading(false);
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  Future<void> signOut() async {
    try {
      await AuthService.instance.signOut();
      Get.offAllNamed('/');
    } catch (e) {
      AppSnackbar.to.error('Erro ao fazer logout');
    }
  }
}
