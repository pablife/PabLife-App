import 'package:flutter/material.dart';
import '../../../infra/models/mentoria_video_model.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';

class MentoriaVideoTile extends StatelessWidget {
  final MentoriaVideoModel video;
  final bool isExpanded;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;

  const MentoriaVideoTile({
    super.key,
    required this.video,
    required this.isExpanded,
    this.isLoading = false,
    required this.onTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 8,
          ),
          leading: Icon(
            Icons.play_arrow,
            color: const Color(0xFF00343C),
            size: 32,
          ),
          title: TextDefault(
            video.title,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF00343C),
          ),
          onTap: onTap,
        ),

        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: GestureDetector(
              onTap: isLoading ? null : onPlayTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLoading)
                      Container(
                        width: double.infinity,
                        height: 187,
                        color: const Color(0xFF00343C).withAlpha(26),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFC1CDFF),
                          ),
                        ),
                      )
                    else
                      _VideoThumbnail(
                        thumbnailUrl: video.resolvedThumbnailUrl,
                        videoTitle: video.title,
                      ),
                    if (!isLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withAlpha(102),
                                Colors.black.withAlpha(153),
                              ],
                              stops: const [0.0, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                    if (!isLoading)
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(186),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Color(0xFF242729),
                            size: 32,
                          ),
                        ),
                      ),
                    if (!isLoading)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black87,
                                  ),
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            if (video.durationSeconds > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                video.formattedDuration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
                                      color: Colors.black87,
                                    ),
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            height: 1,
            color: const Color(0xFF00343C).withAlpha(38),
          ),
        ),
      ],
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String thumbnailUrl;
  final String videoTitle;

  const _VideoThumbnail({required this.thumbnailUrl, required this.videoTitle});

  @override
  Widget build(BuildContext context) {
    debugPrint('[MentoriaVideoTile] Exibindo thumbnail: $thumbnailUrl');

    return AppImage(
      imageUrl: thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 187,
      placeholder: Container(
        width: double.infinity,
        height: 187,
        color: const Color(0xFF00343C).withAlpha(26),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFC1CDFF),
          ),
        ),
      ),
      errorWidget: Container(
        width: double.infinity,
        height: 187,
        color: const Color(0xFF00343C).withAlpha(26),
        child: const Center(
          child: Icon(Icons.video_library, color: Color(0xFFC1CDFF), size: 48),
        ),
      ),
    );
  }
}
