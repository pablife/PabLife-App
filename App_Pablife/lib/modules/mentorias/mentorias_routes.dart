import 'package:get/get.dart';
import 'mentorias_controller.dart';
import 'mentorias_page.dart';
import 'mentoria_view_page.dart';
import 'mentoria_view_controller.dart';
import 'pages/youtube_player_page.dart';
import 'controllers/youtube_player_controller.dart';
import '../../infra/repositories/mentoria_repository.dart';

final mentoriasRoutes = [
  GetPage(
    name: MentoriasPage.route,
    page: () => const MentoriasPage(),
    bindings: [
      BindingsBuilder.put(MentoriaRepository.new),
      BindingsBuilder.put(MentoriasController.new),
    ],
  ),
  GetPage(
    name: MentoriaViewPage.route,
    page: () => const MentoriaViewPage(),
    bindings: [
      BindingsBuilder.put(MentoriaRepository.new),
      BindingsBuilder.put(() => MentoriaViewController(Get.find())),
    ],
  ),
  GetPage(
    name: YoutubePlayerPage.route,
    page: () => const YoutubePlayerPage(),
    bindings: [BindingsBuilder.put(YoutubePlayerController.new)],
  ),
];
