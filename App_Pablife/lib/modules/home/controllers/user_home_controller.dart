import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/models/banner_model.dart';
import '../../../infra/models/home_view_models.dart';
import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/weekly_task_activity_summary_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/repositories/banner_repository.dart';
import '../../../infra/services/activity_service.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';

class UserHomeController extends GetxController with LoaderManagerMixin {
  static UserHomeController get to => Get.find<UserHomeController>();

  final AuthService _authService = AuthService.instance;
  final ActivityService _activityService = ActivityService.instance;
  final ActivityRepository _activityRepository = ActivityRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final BannerRepository _bannerRepository = BannerRepository();

  UserModel? get user => _authService.currentUser;

  /// Verifica se o usuário pode acessar o Planner
  bool get canAccessPlanner => _authService.canAccessPlanner;

  /// Verifica se o usuário pode acessar as Mentorias
  bool get canAccessMentorias => _authService.canAccessMentorias;

  /// Verifica se o usuário pode agendar consultas
  bool get canScheduleAppointment => _authService.canScheduleAppointment;

  /// Consultas restantes
  int get remainingConsultations => _authService.remainingConsultations;

  /// Verifica se está em trial
  bool get isInTrial => _authService.isInTrial;

  /// Dias restantes no trial
  int? get trialDaysRemaining => _authService.trialDaysRemaining;

  int currentProfessionalIndex = 0;
  List<WeeklyProgressViewModel> _weeklyProgressData = [];
  List<ProfessionalAppointmentModel> _appointments = [];
  List<ProfessionalAppointmentModel> _activeAppointments = [];
  List<BannerModel> banners = [];
  WeeklyTaskActivitySummaryModel? _weeklySummary;

  List<ActivityModel> get _allActivities => _activityService.allActivities;

  @override
  void onInit() {
    super.onInit();
    final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];
    _weeklyProgressData = List.generate(7, (index) {
      return WeeklyProgressViewModel(
        day: dayNames[index],
        completed: 0,
        total: 0,
      );
    });
    loadActivities();
    loadWeeklyProgress();
    _loadAppointments();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    final response = await _bannerRepository.getActiveBanners();

    if (response.success && response.data != null) {
      banners = response.data!;
      update();
    }
  }

  Future<void> _loadAppointments() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.id == null) return;

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      // Fetch weekly appointments for progress (if needed)
      final appointmentsResponse = await _appointmentRepository
          .getPatientAppointments(
            patientId: currentUser!.id!,
            startAt: startOfWeek,
            endAt: endOfWeek,
          );

      if (appointmentsResponse.success && appointmentsResponse.data != null) {
        _appointments = appointmentsResponse.data!;
        debugPrint(
          '✅ [UserHome] ${_appointments.length} consultas da semana carregadas',
        );
      } else {
        _appointments = [];
      }

      // Fetch active appointments for the list
      final activeAppointmentsResponse = await _appointmentRepository
          .getPatientActiveAppointments(patientId: currentUser.id!);

      if (activeAppointmentsResponse.success &&
          activeAppointmentsResponse.data != null) {
        _activeAppointments = activeAppointmentsResponse.data!;
        debugPrint(
          '✅ [UserHome] ${_activeAppointments.length} consultas ativas carregadas',
        );
      } else {
        _activeAppointments = [];
      }

      update();
    } catch (e) {
      debugPrint('❌ [UserHome] Erro ao carregar consultas: $e');
      _appointments = [];
      _activeAppointments = [];
    }
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

  Future<void> loadActivities({bool showLoader = true}) async {
    if (showLoader) {
      changeLoading(true);
    }
    try {
      await _activityService.loadAllActivities();
      update();
    } catch (e) {
      debugPrint('DEBUG: Error loading activities: $e');
    } finally {
      if (showLoader) {
        changeLoading(false);
      }
    }
  }

  Future<void> refreshData() async {
    await Future.wait([
      loadActivities(),
      loadWeeklyProgress(),
      _loadAppointments(),
      _loadBanners(),
    ]);
  }

  Future<void> refreshDataSilent() async {
    await Future.wait([
      loadActivities(showLoader: false),
      loadWeeklyProgress(),
      _loadAppointments(),
      _loadBanners(),
    ]);
  }

  Future<void> loadWeeklyProgress() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _activityRepository.getWeeklyTaskActivitySummary(
        userId,
      );

      if (response.success && response.data != null) {
        final summary = response.data!;
        _weeklySummary = summary;
        final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

        _weeklyProgressData = summary.weekDayCounts.asMap().entries.map((
          entry,
        ) {
          final index = entry.key;
          final dayCounts = entry.value;
          final total = dayCounts.isNotEmpty ? dayCounts[0] : 0;
          final completed = dayCounts.length > 1 ? dayCounts[1] : 0;

          final dayName = dayNames[index];

          return WeeklyProgressViewModel(
            day: dayName,
            completed: completed,
            total: total,
          );
        }).toList();
      } else {
        _weeklySummary = null;
        final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

        _weeklyProgressData = List.generate(7, (index) {
          return WeeklyProgressViewModel(
            day: dayNames[index],
            completed: 0,
            total: 0,
          );
        });
      }
      update();
    } catch (e) {
      _weeklySummary = null;
      final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

      _weeklyProgressData = List.generate(7, (index) {
        return WeeklyProgressViewModel(
          day: dayNames[index],
          completed: 0,
          total: 0,
        );
      });
      update();
    }
  }

  List<WeeklyProgressViewModel> get weeklyProgress {
    return _weeklyProgressData;
  }

  bool get hasWeeklyProgress {
    return _weeklyProgressData.any((day) => day.total > 0);
  }

  List<GoalViewModel> get goalCards {
    if (_weeklySummary == null || _weeklySummary!.goals.isEmpty) {
      return [];
    }

    return _weeklySummary!.goals.map((goal) {
      final percentage = goal.percentage;
      String duration = '';

      if (goal.dueAt != null) {
        final daysRemaining = goal.dueAt!.difference(DateTime.now()).inDays;
        if (daysRemaining > 0) {
          duration = daysRemaining > 30
              ? '${(daysRemaining / 30).ceil()} meses'
              : '$daysRemaining dias';
        } else {
          duration = 'Prazo expirado';
        }
      } else {
        duration = 'Sem prazo';
      }

      return GoalViewModel(
        title: goal.name,
        description:
            goal.description ??
            '${percentage.toStringAsFixed(1)}% do prazo decorrido',
        duration: duration,
        tag: 'Meta em andamento:',
        percentage: percentage,
      );
    }).toList();
  }

  List<Map<String, dynamic>> get professionals {
    return [];
  }

  List<TaskViewModel> get todayTasks {
    if (_weeklySummary == null) {
      return [];
    }

    final percentage = _weeklySummary!.tasksPercentage.round();

    return [
      TaskViewModel(label: 'Tarefas Realizadas Hoje', percentage: percentage),
    ];
  }

  List<GoalProgressViewModel> get goalsProgress {
    final goals = _allActivities.where((a) => a.type == 'goal').toList();

    if (goals.isEmpty) {
      return [];
    }

    final colors = [0xFF9CCC65, 0xFFCDDC39, 0xFFFF8A80, 0xFF4FC3F7];

    return goals.take(3).toList().asMap().entries.map((entry) {
      final goal = entry.value;
      if (goal.dueAt == null) {
        return GoalProgressViewModel(
          label: goal.name,
          percentage: 0,
          color: Color(colors[entry.key % colors.length]),
        );
      }
      final totalDays = goal.dueAt!.difference(goal.createdAt).inDays;
      final daysPassed = DateTime.now().difference(goal.createdAt).inDays;
      final percentage = totalDays > 0
          ? ((daysPassed / totalDays) * 100).clamp(0, 100).round()
          : 0;

      return GoalProgressViewModel(
        label: goal.name,
        percentage: percentage,
        color: Color(colors[entry.key % colors.length]),
      );
    }).toList();
  }

  List<Map<String, dynamic>> get registeredMentorias {
    return [];
  }

  bool get isEmpty {
    final hasActiveAppointments = activeAppointments.isNotEmpty;
    final hasTasks = todayTasks.isNotEmpty;
    final hasGoals = goalsProgress.isNotEmpty;
    final hasProfessionals = professionals.isNotEmpty;
    final hasBanners = banners.isNotEmpty;

    return !hasActiveAppointments &&
        !hasWeeklyProgress &&
        !hasTasks &&
        !hasGoals &&
        !hasProfessionals &&
        !hasBanners;
  }

  String selectedPeriod = 'Semana';

  void changeProfessional(int index) {
    currentProfessionalIndex = index;
    update();
  }

  void changePeriod(String period) {
    selectedPeriod = period;
    update();
  }

  void navigateToMotivationalPhrase() {
    AppSnackbar.to.show('Funcionalidade em desenvolvimento');
  }

  void navigateToTodayTasks() {
    AppSnackbar.to.show('Funcionalidade em desenvolvimento');
  }

  void navigateToCompletedTasks() {
    AppSnackbar.to.show('Funcionalidade em desenvolvimento');
  }

  void navigateToMentoria(int index) {
    AppSnackbar.to.show('Funcionalidade em desenvolvimento');
  }
}
