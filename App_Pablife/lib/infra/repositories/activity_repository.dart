import 'dart:convert';
import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/activity_model.dart';
import '../models/weekly_task_activity_summary_model.dart';

class ActivityRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<ActivityModel>> getActivitiesByDate(
    DateTime date, {
    required String userId,
  }) {
    return tryThis(() async {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final dateResponse = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gte('due_at', startOfDay.toIso8601String())
          .lt('due_at', endOfDay.toIso8601String())
          .order('due_at', ascending: true);

      final goalsResponse = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .eq('type', 'goal')
          .isFilter('deleted_at', null)
          .order('due_at', ascending: true);

      final dateActivities = (dateResponse as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      final goals = (goalsResponse as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      final allActivities = <String, ActivityModel>{};
      for (var activity in dateActivities) {
        allActivities[activity.id] = activity;
      }
      for (var goal in goals) {
        allActivities[goal.id] = goal;
      }

      final activities = allActivities.values.toList()
        ..sort((a, b) {
          if (a.dueAt != null && b.dueAt != null) {
            return a.dueAt!.compareTo(b.dueAt!);
          }
          if (a.dueAt != null) return -1;
          if (b.dueAt != null) return 1;
          return 0;
        });

      return StrautilsResponse.success(activities);
    }, action: 'buscar atividades por data.');
  }

  FStrautilsResponse<List<ActivityModel>> getActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    required String userId,
  }) {
    return tryThis(() async {
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      final dateRangeResponse = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gte('due_at', startOfDay.toIso8601String())
          .lt('due_at', endOfDay.toIso8601String())
          .order('due_at', ascending: true);

      final goalsResponse = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .eq('type', 'goal')
          .isFilter('deleted_at', null)
          .order('due_at', ascending: true);

      final dateRangeActivities = (dateRangeResponse as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      final goals = (goalsResponse as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      final allActivities = <String, ActivityModel>{};
      for (var activity in dateRangeActivities) {
        allActivities[activity.id] = activity;
      }
      for (var goal in goals) {
        allActivities[goal.id] = goal;
      }

      final activities = allActivities.values.toList()
        ..sort((a, b) {
          if (a.dueAt != null && b.dueAt != null) {
            return a.dueAt!.compareTo(b.dueAt!);
          }
          if (a.dueAt != null) return -1;
          if (b.dueAt != null) return 1;
          return 0;
        });

      return StrautilsResponse.success(activities);
    }, action: 'buscar atividades por período.');
  }

  FStrautilsResponse<List<ActivityModel>> getActivitiesByType(
    String type, {
    required String userId,
  }) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .eq('type', type)
          .isFilter('deleted_at', null)
          .order('due_at', ascending: true);

      final activities = (response as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'buscar atividades por tipo.');
  }

  FStrautilsResponse<List<ActivityModel>> getActivitiesByStatus(String status) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .select()
          .isFilter('deleted_at', null)
          .order('due_at', ascending: true);

      final activities = (response as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'buscar atividades por status.');
  }

  FStrautilsResponse<List<ActivityModel>> getTodayTasks({
    required String userId,
  }) {
    return tryThis(() async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .eq('type', 'task')
          .isFilter('deleted_at', null)
          .gte('due_at', startOfDay.toIso8601String())
          .lt('due_at', endOfDay.toIso8601String())
          .order('due_at', ascending: true);

      final activities = (response as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'buscar tarefas de hoje.');
  }

  FStrautilsResponse<List<ActivityModel>> getCompletedTasks() {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .select()
          .eq('type', 'task')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false)
          .limit(10);

      final activities = (response as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'buscar tarefas concluídas.');
  }

  FStrautilsResponse<List<ActivityModel>> getAllGoals({
    required String userId,
  }) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('user_id', userId)
          .eq('type', 'goal')
          .isFilter('deleted_at', null)
          .order('due_at', ascending: true);

      final activities = (response as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'buscar todas as metas.');
  }

  FStrautilsResponse<ActivityModel> createActivity(ActivityModel activity) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .insert(activity.toMap())
          .select()
          .single();

      return StrautilsResponse.success(ActivityModel.fromMap(response));
    }, action: 'criar atividade.');
  }

  FStrautilsResponse<ActivityModel> updateActivity(ActivityModel activity) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .update(activity.toMap())
          .eq('id', activity.id)
          .select()
          .single();

      return StrautilsResponse.success(ActivityModel.fromMap(response));
    }, action: 'atualizar atividade.');
  }

  FStrautilsResponse<bool> deleteActivity(String activityId) {
    return tryThis(() async {
      await _client
          .from('tb_activities')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', activityId);

      return StrautilsResponse.success(true);
    }, action: 'deletar atividade.');
  }

  FStrautilsResponse<Map<String, int>> getActivityStatistics() {
    return tryThis(() async {
      final allActivities = await _client
          .from('tb_activities')
          .select()
          .isFilter('deleted_at', null);

      final activities = (allActivities as List)
          .map((item) => ActivityModel.fromMap(item))
          .toList();

      final totalTasks = activities.where((a) => a.type == 'task').length;
      final completedTasks = totalTasks;
      final totalGoals = activities.where((a) => a.type == 'goal').length;
      final completedGoals = totalGoals;
      final totalNotes = activities.where((a) => a.type == 'note').length;

      return StrautilsResponse.success({
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalGoals': totalGoals,
        'completedGoals': completedGoals,
        'totalNotes': totalNotes,
      });
    }, action: 'buscar estatísticas de atividades.');
  }

  FStrautilsResponse<WeeklyTaskActivitySummaryModel?>
  getWeeklyTaskActivitySummary(String userId) {
    return tryThis(() async {
      final response = await _client
          .from('vw_weekly_task_activity_summary')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.success(null);
      }

      return StrautilsResponse.success(
        WeeklyTaskActivitySummaryModel.fromMap(response),
      );
    }, action: 'buscar resumo semanal de atividades.');
  }

  FStrautilsResponse<bool> markActivityAsCompleted(
    String activityId, {
    required DateTime activityDate,
  }) {
    return tryThis(() async {
      final activityDateValue = activityDate.toIso8601String().split('T')[0];

      final existingRegister = await _client
          .from('tb_activity_registers')
          .select()
          .eq('activity_id', activityId)
          .eq('activity_date', activityDateValue)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existingRegister != null) {
        return StrautilsResponse.success(true);
      }

      await _client.from('tb_activity_registers').insert({
        'activity_id': activityId,
        'registered_at': DateTime.now().toIso8601String(),
        'activity_date': activityDateValue,
      });

      return StrautilsResponse.success(true);
    }, action: 'marcar atividade como concluída.');
  }

  FStrautilsResponse<bool> unmarkActivityAsCompleted(
    String activityId, {
    required DateTime activityDate,
  }) {
    return tryThis(() async {
      debugPrint('Activity ID $activityId');
      final activityDateValue = activityDate.toIso8601String().split('T')[0];
      final existingRegister = await _client
          .from('tb_activity_registers')
          .select()
          .eq('activity_id', activityId)
          .eq('activity_date', activityDateValue)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existingRegister == null) {
        return StrautilsResponse.success(true);
      }

      debugPrint('Activity registers ID ${existingRegister['id']}');

      try {
        await _client
            .from('tb_activity_registers')
            .delete()
            .eq('id', existingRegister['id']);
      } catch (error) {
        debugPrint('Error in unmarkActivityAsCompleted: $error');

        // Tratar o erro (ex: mostrar um SnackBar)
      }

      return StrautilsResponse.success(true);
    }, action: 'desmarcar atividade como concluída.');
  }

  FStrautilsResponse<String> createRecurrenceRule({
    required DateTime startAt,
    required List<int> byWeekDay,
    required int weekStart,
  }) {
    return tryThis(() async {
      final timezoneName = tz.local.name;

      final response = await _client
          .from('tb_activity_recurrence_rules')
          .insert({
            'start_at': startAt.toIso8601String(),
            'by_week_day': byWeekDay,
            'week_start': weekStart,
            'timezone': timezoneName,
          })
          .select('id')
          .single();

      return StrautilsResponse.success(response['id'] as String);
    }, action: 'criar regra de recorrência.');
  }

  FStrautilsResponse<Map<String, dynamic>?> getRecurrenceRuleById(
    String recurrenceRuleId,
  ) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activity_recurrence_rules')
          .select()
          .eq('id', recurrenceRuleId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.success(null);
      }

      return StrautilsResponse.success(
        Map<String, dynamic>.from(response as Map),
      );
    }, action: 'buscar regra de recorrência.');
  }

  FStrautilsResponse<bool> updateRecurrenceRule({
    required String recurrenceRuleId,
    required DateTime startAt,
    required List<int> byWeekDay,
    required int weekStart,
    required String timezone,
  }) {
    return tryThis(() async {
      await _client
          .from('tb_activity_recurrence_rules')
          .update({
            'start_at': startAt.toIso8601String(),
            'by_week_day': byWeekDay,
            'week_start': weekStart,
            'timezone': timezone,
          })
          .eq('id', recurrenceRuleId);

      return StrautilsResponse.success(true);
    }, action: 'atualizar regra de recorrência.');
  }

  FStrautilsResponse<List<ActivityModel>> loadActivitiesForDate(
    DateTime targetDate,
  ) {
    return tryThis(() async {
      final formattedDate = targetDate.toIso8601String().split('T')[0];

      final rows = await _client.rpc(
        'get_user_calendar_events',
        params: {'target_date': formattedDate},
      );

      log(
        '✅ [ActivityRepository] Atividades carregadas para a data $formattedDate: ${jsonEncode(rows)}.',
      );

      final activities = (rows as List)
          .map(
            (event) => ActivityModel.fromEvent(event as Map<String, dynamic>),
          )
          .toList();

      return StrautilsResponse.success(activities);
    }, action: 'carregar atividades para a data.');
  }

  FStrautilsResponse<ActivityModel?> getActivityById(String activityId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_activities')
          .select(
            '*, tb_activity_registers!left(id, registered_at, activity_date, deleted_at)',
          )
          .eq('id', activityId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.success(null);
      }

      return StrautilsResponse.success(ActivityModel.fromMap(response));
    }, action: 'buscar atividade por ID.');
  }
}
