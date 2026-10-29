import 'package:flutter/material.dart';
import '../../../infra/models/mentoria_model.dart';
import '../../../widgets/design_system/text_default.dart';
import 'mentoria_image_widget.dart';

class MentoriaTile extends StatelessWidget {
  final MentoriaModel mentoria;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const MentoriaTile({
    super.key,
    required this.mentoria,
    required this.onTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 149,
        decoration: BoxDecoration(
          color: mentoria.isSaved
              ? const Color(0xFF9ECAD0)
              : const Color(0xFFAEBEEC),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Row(
              children: [
                MentoriaImageWidget(imageUrl: mentoria.bannerUrl),
                const SizedBox(width: 18),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextDefault(
                          mentoria.title,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF00343C),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          height: 1.2,
                        ),
                        const SizedBox(height: 2),
                        TextDefault(
                          'Duração ${mentoria.durationLabel}',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00343C),
                          maxLines: 1,
                          height: 1.2,
                        ),
                        const SizedBox(height: 4),
                        TextDefault(
                          mentoria.description,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withAlpha(143),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          height: 1.25,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onBookmarkTap,
                child: Container(
                  width: 49.24,
                  height: 48.5,
                  decoration: BoxDecoration(
                    color: mentoria.isSaved
                        ? const Color(0xFF0C8DA1)
                        : const Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    mentoria.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: mentoria.isSaved
                        ? Colors.white
                        : const Color(0xFF00343C),
                    size: 20,
                  ),
                ),
              ),
            ),
            if (mentoria.isLocked)
              Positioned(
                left: 27.5,
                top: 37,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: const Icon(Icons.lock, color: Colors.white, size: 40),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
