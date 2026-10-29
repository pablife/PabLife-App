import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as yt_player;
import '../../../infra/services/youtube_service.dart';

class YoutubePlayerController extends GetxController {
  final YoutubeService _youtubeService = YoutubeService.instance;

  yt_player.YoutubePlayerController? playerController;
  String? videoTitle;
  String? videoDescription;
  bool isLoading = true;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      videoTitle = args['videoTitle'] as String?;
      final videoUrl = args['videoUrl'] as String?;
      final videoId = args['videoId'] as String?;
      if (videoUrl != null || videoId != null) {
        _initializePlayer(videoUrl: videoUrl, videoId: videoId);
      } else {
        isLoading = false;
        update();
      }
    } else {
      isLoading = false;
      update();
    }
  }

  Future<void> _initializePlayer({String? videoUrl, String? videoId}) async {
    try {
      String? finalVideoId = videoId;

      if (finalVideoId == null && videoUrl != null) {
        finalVideoId = _extractVideoId(videoUrl);
      }

      if (finalVideoId == null) {
        debugPrint('[YoutubePlayerController] ID do vídeo não encontrado');
        isLoading = false;
        update();
        return;
      }

      debugPrint(
        '[YoutubePlayerController] Inicializando player: $finalVideoId',
      );

      final youtubeInfo = await _youtubeService.getVideoInfo(
        videoUrl ?? 'https://www.youtube.com/watch?v=$finalVideoId',
      );

      if (youtubeInfo != null) {
        videoDescription = youtubeInfo.title;
      }

      playerController = yt_player.YoutubePlayerController(
        initialVideoId: finalVideoId,
        flags: const yt_player.YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );

      isLoading = false;
      update();
    } catch (e) {
      debugPrint('[YoutubePlayerController] Erro ao inicializar player: $e');
      isLoading = false;
      update();
    }
  }

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }

    if (uri.host.contains('youtube.com')) {
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  void Function(bool)? _onFullscreenChanged;

  void onPlayerReady(void Function(bool) onFullscreenChanged) {
    debugPrint('[YoutubePlayerController] Player pronto');
    _onFullscreenChanged = onFullscreenChanged;
    _setupFullscreenListener();
  }

  void _setupFullscreenListener() {
    playerController?.addListener(() {
      final isFullscreen = playerController?.value.isFullScreen ?? false;
      debugPrint('[YoutubePlayerController] Fullscreen: $isFullscreen');
      _onFullscreenChanged?.call(isFullscreen);
    });
  }

  @override
  void onClose() {
    playerController?.dispose();
    super.onClose();
  }
}
