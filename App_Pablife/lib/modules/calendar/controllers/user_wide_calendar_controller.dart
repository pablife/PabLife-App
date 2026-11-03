import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../home/controllers/user_home_controller.dart';
import '../../appointment_details/widgets/patient_appointment_options_sheet.dart';
import '../calendar_controller.dart';
import '../pages/activity_details_page.dart';
import '../repositories/calendar_repository.dart';
import 'professional_wide_calendar_controller.dart';

/// Quantidade de itens de cada tipo num dia (visões Mês e Ano).
class UserDayCounts {
  final int goals;
  final int tasks;
  final int notes;
  final int appointments;

  const UserDayCounts({
    this.goals = 0,
    this.tasks = 0,
    this.notes = 0,
    this.appointments = 0,
  });
}

/// Agenda do usuário no computador (semana, mês e ano), com as tarefas,
/// metas, anotações e consultas do planner. Criar itens reaproveita o
/// [CalendarController], o mesmo do planner do celular.
class UserWideCalendarController extends GetxController
    with LoaderManagerMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final CalendarRepository _calendarRepository = CalendarRepository();

  WideAgendaView view = WideAgendaView.week;
  DateTime focusDate = _dateOnly(DateTime.now());

  /// Caixas "Mostrar" da coluna da esquerda.
  bool showTasks = true;
  bool showGoals = true;
  bool showNotes = true;
  bool showAppointments = true;

  /// Itens de cada dia da semana mostrada (visão Semana).
  Map<DateTime, List<ActivityModel>> _eventsByDay = {};

  /// Contagens por dia (visões Mês e Ano).
  Map<DateTime, UserDayCounts> _countsByDay = {};
  int _loadToken = 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ---------------------------------------------------------------- período

  DateTime get rangeStart {
    switch (view) {
      case WideAgendaView.day:
        return focusDate;
      case WideAgendaView.week:
        return ProfessionalWideCalendarController.weekStart(focusDate);
      case WideAgendaView.month:
        return ProfessionalWideCalendarController.weekStart(
          DateTime(focusDate.year, focusDate.month, 1),
        );
      case WideAgendaView.year:
        return DateTime(focusDate.year, 1, 1);
    }
  }

  DateTime get rangeEnd {
    switch (view) {
      case WideAgendaView.day:
        return rangeStart.add(const Duration(days: 1));
      case WideAgendaView.week:
        return rangeStart.add(const Duration(days: 7));
      case WideAgendaView.month:
        return rangeStart.add(const Duration(days: 42));
      case WideAgendaView.year:
        return DateTime(focusDate.year + 1, 1, 1);
    }
  }

  /// Dias mostrados na grade de horas: só o dia (visão Dia) ou a semana.
  List<DateTime> get weekDays => List.generate(
    view == WideAgendaView.day ? 1 : 7,
    (i) => DateTime(rangeStart.year, rangeStart.month, rangeStart.day + i),
  );

  String get title {
    const months = ProfessionalWideCalendarController.monthNames;
    switch (view) {
      case WideAgendaView.day:
        return ProfessionalWideCalendarController.dayTitle(focusDate);
      case WideAgendaView.week:
        final start = rangeStart;
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${months[start.month - 1]} de ${start.year}';
        }
        final a = months[start.month - 1].substring(0, 3);
        final b = months[end.month - 1].substring(0, 3);
        return start.year == end.year
            ? '$a – $b de ${end.year}'
            : '$a de ${start.year} – $b de ${end.year}';
      case WideAgendaView.month:
        return '${months[focusDate.month - 1]} de ${focusDate.year}';
      case WideAgendaView.year:
        return '${focusDate.year}';
    }
  }

  // ---------------------------------------------------------------- dados

  Future<void> load() async {
    final token = ++_loadToken;
    changeLoading(true);
    try {
      if (view == WideAgendaView.day || view == WideAgendaView.week) {
        final days = weekDays;
        // Uma busca por dia (a mesma do planner), todas ao mesmo tempo.
        final responses = await Future.wait(
          days.map(_activityRepository.loadActivitiesForDate),
        );
        if (token != _loadToken) return;
        _eventsByDay = {
          for (var i = 0; i < days.length; i++)
            days[i]: responses[i].success
                ? responses[i].data ?? <ActivityModel>[]
                : <ActivityModel>[],
        };
      } else {
        final counts = await _loadCounts(rangeStart, rangeEnd);
        if (token != _loadToken) return;
        _countsByDay = counts;
      }
    } catch (e) {
      debugPrint('❌ [UserWideCalendar] Erro ao carregar agenda: $e');
    } finally {
      if (token == _loadToken) {
        changeLoading(false);
        update();
      }
    }
  }

  /// A função de contagem do banco aceita no máximo ~30 dias por chamada,
  /// então o período é buscado em partes.
  Future<Map<DateTime, UserDayCounts>> _loadCounts(
    DateTime start,
    DateTime end,
  ) async {
    final format = DateFormat('yyyy-MM-dd');
    final chunks = <Future<List<Map<String, dynamic>>>>[];
    for (var s = start; s.isBefore(end); s = s.add(const Duration(days: 30))) {
      final e = s.add(const Duration(days: 29));
      chunks.add(
        _calendarRepository.getPatientCalendarCounts(
          startDate: format.format(s),
          endDate: format.format(e),
        ),
      );
    }

    final result = <DateTime, UserDayCounts>{};
    for (final rows in await Future.wait(chunks)) {
      for (final row in rows) {
        final day = DateTime.parse(row['day_date'] as String);
        if (day.isBefore(start) || !day.isBefore(end)) continue;
        result[_dateOnly(day)] = UserDayCounts(
          goals: row['goal_count'] as int? ?? 0,
          tasks: row['task_count'] as int? ?? 0,
          notes: row['note_count'] as int? ?? 0,
          appointments: row['appointment_count'] as int? ?? 0,
        );
      }
    }
    return result;
  }

  bool _visible(ActivityModel activity) => switch (activity.type) {
    'goal' => showGoals,
    'note' => showNotes,
    'appointment' => showAppointments,
    _ => showTasks,
  };

  /// Itens do dia (visão Semana), respeitando as caixas "Mostrar".
  List<ActivityModel> eventsOn(DateTime day) =>
      (_eventsByDay[_dateOnly(day)] ?? const []).where(_visible).toList()..sort(
        (a, b) => (a.dueAt ?? DateTime(0)).compareTo(b.dueAt ?? DateTime(0)),
      );

  /// Contagens do dia (visões Mês e Ano), respeitando as caixas "Mostrar".
  UserDayCounts countsOn(DateTime day) {
    final c = _countsByDay[_dateOnly(day)] ?? const UserDayCounts();
    return UserDayCounts(
      goals: showGoals ? c.goals : 0,
      tasks: showTasks ? c.tasks : 0,
      notes: showNotes ? c.notes : 0,
      appointments: showAppointments ? c.appointments : 0,
    );
  }

  /// Totais do período mostrado, para as caixas "Mostrar".
  UserDayCounts get totals {
    if (view == WideAgendaView.day || view == WideAgendaView.week) {
      final all = _eventsByDay.values.expand((e) => e).toList();
      int count(bool Function(ActivityModel) test) => all.where(test).length;
      return UserDayCounts(
        // Uma meta aparece em todos os dias do período; conta uma vez.
        goals: all
            .where((a) => a.type == 'goal')
            .map((a) => a.id)
            .toSet()
            .length,
        tasks: count((a) => a.type == 'task'),
        notes: count((a) => a.type == 'note'),
        appointments: count((a) => a.type == 'appointment'),
      );
    }
    var goals = 0, tasks = 0, notes = 0, appointments = 0;
    for (final c in _countsByDay.values) {
      goals += c.goals;
      tasks += c.tasks;
      notes += c.notes;
      appointments += c.appointments;
    }
    return UserDayCounts(
      goals: goals,
      tasks: tasks,
      notes: notes,
      appointments: appointments,
    );
  }

  // ---------------------------------------------------------------- navegação

  void setView(WideAgendaView newView) {
    if (view == newView) return;
    view = newView;
    update();
    load();
  }

  /// "Hoje" abre só o dia de hoje (visão Dia), como no Google Agenda.
  void goToday() {
    focusDate = _dateOnly(DateTime.now());
    view = WideAgendaView.day;
    update();
    load();
  }

  void move(int direction) {
    switch (view) {
      case WideAgendaView.day:
        focusDate = focusDate.add(Duration(days: direction));
      case WideAgendaView.week:
        focusDate = focusDate.add(Duration(days: 7 * direction));
      case WideAgendaView.month:
        focusDate = DateTime(focusDate.year, focusDate.month + direction, 1);
      case WideAgendaView.year:
        focusDate = DateTime(focusDate.year + direction, focusDate.month, 1);
    }
    update();
    load();
  }

  void openDay(DateTime day) {
    focusDate = _dateOnly(day);
    view = WideAgendaView.day;
    update();
    load();
  }

  void setFilter({bool? tasks, bool? goals, bool? notes, bool? appointments}) {
    showTasks = tasks ?? showTasks;
    showGoals = goals ?? showGoals;
    showNotes = notes ?? showNotes;
    showAppointments = appointments ?? showAppointments;
    update();
  }

  // ---------------------------------------------------------------- ações

  CalendarController get _planner => Get.find<CalendarController>();

  Future<void> createTask() async {
    await _planner.createTask();
    await load();
  }

  Future<void> createGoal() async {
    await _planner.createGoal();
    await load();
  }

  Future<void> createNote() async {
    await _planner.createNote();
    await load();
  }

  /// Marca/desmarca tarefa, meta ou anotação como feita no dia, como o
  /// check do planner do celular. A tela muda na hora e volta se der erro.
  Future<void> toggleDone(ActivityModel activity, DateTime day) async {
    final key = _dateOnly(day);
    final done = !activity.isCompleted;
    // Usa a data do item no dia (a mesma regra do planner do celular).
    final activityDate = activity.activityDate ?? key;

    void setDone(bool value) {
      final list = _eventsByDay[key];
      if (list == null) return;
      final i = list.indexWhere((a) => a.id == activity.id);
      if (i == -1) return;
      list[i] = list[i].copyWith(
        isCompleted: value,
        completedAt: value ? DateTime.now() : null,
      );
      update();
    }

    setDone(done);
    final response = done
        ? await _activityRepository.markActivityAsCompleted(
            activity.id,
            activityDate: activityDate,
          )
        : await _activityRepository.unmarkActivityAsCompleted(
            activity.id,
            activityDate: activityDate,
          );
    if (!response.success) {
      setDone(!done);
      AppSnackbar.to.show(
        'Erro ao ${done ? 'marcar' : 'desmarcar'}: ${response.message}',
      );
      return;
    }
    // Atualiza o Dashboard (tarefas do dia e % de dias cumpridos das metas).
    UserHomeController.to.refreshData();
  }

  /// Consulta abre as opções (remarcar, cancelar...); o resto abre os
  /// detalhes, como no planner.
  Future<void> openItem(ActivityModel activity) async {
    if (activity.type == 'appointment') {
      final changed = await PatientAppointmentOptionsSheet.showById(
        activity.id,
      );
      if (changed) await load();
      return;
    }
    await Get.toNamed(ActivityDetailsPage.route, arguments: activity);
    await load();
  }
}
