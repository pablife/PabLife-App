import 'package:get/get.dart';

import 'calendar_page.dart';
import 'calendar_controller.dart';
import 'controllers/calendar_switcher_controller.dart';
import 'controllers/professional_calendar_controller.dart';
import 'controllers/interactive_calendar_controller.dart';
import 'controllers/selected_day_controller.dart';
import 'controllers/professional_selected_day_controller.dart';
import 'pages/interactive_calendar_page.dart';
import 'pages/selected_day_page.dart';
import 'pages/professional_selected_day_page.dart';
import 'pages/task_editor_page.dart';
import 'pages/goal_editor_page.dart';
import 'pages/note_editor_page.dart';
import 'pages/goal_suggestions_page.dart';
import 'controllers/task_editor_controller.dart';
import 'controllers/goal_editor_controller.dart';
import 'controllers/note_editor_controller.dart';
import 'controllers/goal_suggestions_controller.dart';
import 'pages/activity_details_page.dart';
import 'controllers/activity_details_controller.dart';

final calendarRoutes = [
  GetPage(
    name: CalendarPage.route,
    page: () => const CalendarPage(),
    bindings: [
      BindingsBuilder(() {
        Get.put(CalendarSwitcherController());
        if (!Get.isRegistered<CalendarController>()) {
          Get.lazyPut(() => CalendarController(), fenix: true);
        }
        if (!Get.isRegistered<ProfessionalCalendarController>()) {
          Get.lazyPut(() => ProfessionalCalendarController(), fenix: true);
        }
        if (!Get.isRegistered<InteractiveCalendarController>()) {
          Get.lazyPut(() => InteractiveCalendarController(), fenix: true);
        }
      }),
    ],
  ),
  GetPage(
    name: InteractiveCalendarPage.route,
    page: () => const InteractiveCalendarPage(),
    bindings: [BindingsBuilder.put(InteractiveCalendarController.new)],
  ),
  GetPage(
    name: TaskEditorPage.route,
    page: () => const TaskEditorPage(),
    bindings: [BindingsBuilder.put(TaskEditorController.new)],
  ),
  GetPage(
    name: GoalEditorPage.route,
    page: () => const GoalEditorPage(),
    bindings: [BindingsBuilder.put(GoalEditorController.new)],
  ),
  GetPage(
    name: NoteEditorPage.route,
    page: () => const NoteEditorPage(),
    bindings: [BindingsBuilder.put(NoteEditorController.new)],
  ),
  GetPage(
    name: GoalSuggestionsPage.route,
    page: () => const GoalSuggestionsPage(),
    bindings: [BindingsBuilder.put(GoalSuggestionsController.new)],
  ),
  GetPage(
    name: ActivityDetailsPage.route,
    page: () => const ActivityDetailsPage(),
    bindings: [BindingsBuilder.put(ActivityDetailsController.new)],
  ),
  GetPage(
    name: SelectedDayPage.route,
    page: () => const SelectedDayPage(),
    bindings: [BindingsBuilder.put(SelectedDayController.new)],
  ),
  GetPage(
    name: ProfessionalSelectedDayPage.route,
    page: () => const ProfessionalSelectedDayPage(),
    bindings: [BindingsBuilder.put(ProfessionalSelectedDayController.new)],
  ),
];
