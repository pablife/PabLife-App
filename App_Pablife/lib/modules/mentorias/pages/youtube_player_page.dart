import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pablife/shared/themes/app_colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as yt_player;
import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/youtube_player_controller.dart';

class YoutubePlayerPage extends StatefulWidget {
  const YoutubePlayerPage({super.key});

  static const route = '/mentoria/youtube-player';

  @override
  State<YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onFullscreenChanged(bool isFullscreen) {
    setState(() {
      _isFullscreen = isFullscreen;
    });

    if (isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<YoutubePlayerController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          extendBodyBehindAppBar: !_isFullscreen,
          appBar: _isFullscreen ? null : AppBarDefault(title: ''),
          body: SafeArea(
            top: !_isFullscreen,
            child: Column(
              children: [
                if (controller.isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC1CDFF),
                      ),
                    ),
                  )
                else if (controller.playerController != null)
                  Expanded(
                    child: Container(
                      color: AppColors.second,
                      child: yt_player.YoutubePlayerBuilder(
                        onExitFullScreen: () {
                          _onFullscreenChanged(false);
                        },
                        player: yt_player.YoutubePlayer(
                          controller: controller.playerController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: const Color(0xFFC1CDFF),
                          progressColors: const yt_player.ProgressBarColors(
                            playedColor: Color(0xFFC1CDFF),
                            handleColor: Color(0xFFC1CDFF),
                            bufferedColor: Color(0xFFC1CDFF),
                            backgroundColor: Color(0xFF00343C),
                          ),
                          onReady: () {
                            controller.onPlayerReady(_onFullscreenChanged);
                          },
                        ),
                        builder: (context, player) {
                          return Column(
                            children: [
                              if (!_isFullscreen)
                                AspectRatio(aspectRatio: 16 / 9, child: player)
                              else
                                Expanded(child: player),
                              if (!_isFullscreen &&
                                  (controller.videoTitle != null ||
                                      controller.videoDescription != null))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC1CDFF),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (controller.videoTitle != null) ...[
                                        TextDefault(
                                          controller.videoTitle!,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF00343C),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFC1CDFF),
                          ),
                          const SizedBox(height: 16),
                          const TextDefault(
                            'Erro ao carregar o vídeo',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFC1CDFF),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC1CDFF),
                              foregroundColor: const Color(0xFF00343C),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const TextDefault(
                              'Voltar',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00343C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
