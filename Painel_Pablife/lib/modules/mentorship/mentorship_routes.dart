import 'package:get/get.dart';
import 'mentorship_page.dart';
import 'mentorship_controller.dart';
import 'pages/mentorship_create_page.dart';
import 'pages/mentorship_edit_page.dart';
import 'mentorship_details/mentorship_details_page.dart';
import 'pages/module_form_page.dart';
import 'pages/lesson_form_page.dart';
import '../../infra/middlewares/auth_guard.dart';

class MentorshipRoutes {
  MentorshipRoutes._();

  static const String mentorshipList = '/mentorships';
  static const String mentorshipCreate = '/mentorships/create';
  static const String mentorshipEdit = '/mentorships/edit';
  static const String mentorshipDetails = '/mentorships/details';
  static const String moduleForm = '/mentorships/module/form';
  static const String lessonForm = '/mentorships/lesson/form';

  static List<GetPage> routes = [
    GetPage(
      name: mentorshipList,
      page: () => const MentorshipPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
    GetPage(
      name: mentorshipCreate,
      page: () => const MentorshipCreatePage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
    GetPage(
      name: mentorshipEdit,
      page: () => const MentorshipEditPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
    GetPage(
      name: mentorshipDetails,
      page: () => const MentorshipDetailsPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
    GetPage(
      name: moduleForm,
      page: () => const ModuleFormPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
    GetPage(
      name: lessonForm,
      page: () => const LessonFormPage(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MentorshipController());
      }),
    ),
  ];
}
