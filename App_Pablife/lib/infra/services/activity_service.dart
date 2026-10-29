import 'package:get/get.dart';
import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';
import 'auth_service.dart';

class ActivityService extends GetxController {
  static ActivityService get instance => Get.find<ActivityService>();

  final ActivityRepository _activityRepository = ActivityRepository();
  final AuthService _authService = AuthService.instance;

  List<ActivityModel> _allActivities = [];
  List<ActivityModel> _goals = [];
  List<ActivityModel> _tasks = [];
  List<ActivityModel> _notes = [];

  List<ActivityModel> get allActivities => _allActivities;
  List<ActivityModel> get goals => _goals;
  List<ActivityModel> get tasks => _tasks;
  List<ActivityModel> get notes => _notes;

  Future<void> loadAllActivities() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 13));

      final response = await _activityRepository.getActivitiesByDateRange(
        startOfWeek,
        endOfWeek,
        userId: userId,
      );

      if (response.success && response.data != null) {
        _allActivities = response.data!;
        _updateCategorizedLists();
      }
    } catch (e) {
      // Ignore errors during background refresh
    }
  }

  Future<List<ActivityModel>> loadActivitiesForDate(DateTime date) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _activityRepository.getActivitiesByDate(
        date,
        userId: userId,
      );
      if (response.success && response.data != null) {
        return response.data!;
      }
    } catch (e) {
      // Ignore errors when loading activities for date
    }
    return [];
  }

  void addActivity(ActivityModel activity) {
    _allActivities.add(activity);
    _updateCategorizedLists();
  }

  void updateActivity(ActivityModel activity) {
    final index = _allActivities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _allActivities[index] = activity;
      _updateCategorizedLists();
    }
  }

  void removeActivity(String activityId) {
    _allActivities.removeWhere((a) => a.id == activityId);
    _updateCategorizedLists();
  }

  void _updateCategorizedLists() {
    _goals = _allActivities.where((a) => a.type == 'goal').toList();
    _tasks = _allActivities.where((a) => a.type == 'task').toList();
    _notes = _allActivities.where((a) => a.type == 'note').toList();
  }

  @override
  Future<void> refresh() async {
    await loadAllActivities();
  }
}
