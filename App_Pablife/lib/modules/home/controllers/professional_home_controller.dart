import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/repositories/banner_repository.dart';
import '../../../infra/models/banner_model.dart';
import '../../../shared/mixins/loader_manager.dart';

class ProfessionalHomeController extends GetxController
    with LoaderManagerMixin {
  static ProfessionalHomeController get to =>
      Get.find<ProfessionalHomeController>();
  final AuthService _authService = AuthService.instance;
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final BannerRepository _bannerRepository = BannerRepository();

  ProfessionalModel? professional;
  List<ProfessionalAppointmentModel> _appointments = [];
  List<ProfessionalAppointmentModel> _activeAppointments = [];
  List<BannerModel> banners = [];

  UserModel? get user => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadDashboard();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    final response = await _bannerRepository.getActiveBanners();

    if (response.success && response.data != null) {
      banners = response.data!;
      update();
    }
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    if (showLoader) {
      changeLoading(true);
    }
    try {
      debugPrint('🏠 [ProfessionalHome] Iniciando carregamento do dashboard');
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        debugPrint('❌ [ProfessionalHome] Usuário não autenticado');
        return;
      }
      debugPrint('🏠 [ProfessionalHome] User ID: ${currentUser!.id}');

      final professionalResponse = await _professionalRepository
          .getProfessionalByUserId(currentUser.id!);

      if (!professionalResponse.success || professionalResponse.data == null) {
        debugPrint('❌ [ProfessionalHome] Profissional não encontrado');
        return;
      }

      professional = professionalResponse.data;
      debugPrint('✅ [ProfessionalHome] Profissional: ${professional!.id}');

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      debugPrint('🏠 [ProfessionalHome] Buscando consultas da semana');
      debugPrint('🏠 [ProfessionalHome] StartOfWeek: $startOfWeek');
      debugPrint('🏠 [ProfessionalHome] EndOfWeek: $endOfWeek');

      // Fetch weekly appointments for progress
      final appointmentsResponse = await _appointmentRepository
          .getProfessionalAppointments(
            professionalId: professional!.id!,
            startAt: startOfWeek,
            endAt: endOfWeek,
          );

      if (appointmentsResponse.success && appointmentsResponse.data != null) {
        _appointments = appointmentsResponse.data!;
        debugPrint(
          '✅ [ProfessionalHome] ${_appointments.length} consultas da semana carregadas',
        );
      } else {
        _appointments = [];
        debugPrint(
          '⚠️ [ProfessionalHome] Nenhuma consulta da semana encontrada',
        );
      }

      // Fetch active appointments for the list
      final activeAppointmentsResponse = await _appointmentRepository
          .getProfessionalActiveAppointments(professionalId: professional!.id!);

      if (activeAppointmentsResponse.success &&
          activeAppointmentsResponse.data != null) {
        _activeAppointments = activeAppointmentsResponse.data!;
        debugPrint(
          '✅ [ProfessionalHome] ${_activeAppointments.length} consultas ativas carregadas',
        );
      } else {
        _activeAppointments = [];
        debugPrint('⚠️ [ProfessionalHome] Nenhuma consulta ativa encontrada');
      }
    } finally {
      if (showLoader) {
        changeLoading(false);
      }
      update();
    }
  }

  /// Recarrega todos os dados da tela inicial do profissional
  Future<void> refreshData() async {
    await Future.wait([_loadDashboard(), _loadBanners()]);
  }

  Future<void> refreshDataSilent() async {
    await Future.wait([
      _loadDashboard(showLoader: false),
      _loadBanners(),
    ]);
  }

  List<ProfessionalAppointmentModel> get activeAppointments =>
      _activeAppointments;

  List<ProfessionalAppointmentModel> get todayAppointments {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    return _appointments.where((appointment) {
      final start = appointment.startAt.toLocal();
      return !start.isBefore(startOfToday) && !start.isAfter(endOfToday);
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  List<Map<String, dynamic>> get weeklyProgress {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

    return List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );

      final dayAppointments = _appointments.where((appointment) {
        final start = appointment.startAt.toLocal();
        return !start.isBefore(dayStart) && !start.isAfter(dayEnd);
      }).toList();

      final completed = dayAppointments
          .where((appointment) => appointment.isCompleted)
          .length;
      final total = dayAppointments.length;

      return {
        'day': dayNames[day.weekday % 7],
        'completed': completed,
        'total': total,
      };
    });
  }

  Map<String, dynamic>? get todayConsultationsProgress {
    final appointments = todayAppointments;
    if (appointments.isEmpty) {
      return null;
    }

    final completed = appointments
        .where((appointment) => appointment.isCompleted)
        .length;
    final total = appointments.length;
    final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

    return {'label': 'Consultas hoje', 'percentage': percentage};
  }

  int get weeklyCompletedCount =>
      _appointments.where((appointment) => appointment.isCompleted).length;

  int get weeklyTotalCount => _appointments.length;

  bool get isEmpty {
    final hasActiveAppointments = activeAppointments.isNotEmpty;
    final hasWeeklyProgress = weeklyProgress.any(
      (day) => (day['total'] as int) > 0,
    );
    final hasProgress = todayConsultationsProgress != null;

    return !hasActiveAppointments && !hasWeeklyProgress && !hasProgress;
  }
}
