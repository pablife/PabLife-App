import 'package:flutter/material.dart';

import '../../../widgets/design_system/app_image.dart';

class MentoriaImageWidget extends StatelessWidget {
  final String imageUrl;

  const MentoriaImageWidget({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 109,
      height: 127,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(17)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: Container(
                color: const Color(0xFF00343C).withAlpha(51),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00343C),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: Container(
                color: const Color(0xFF00343C).withAlpha(51),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Color(0xFF00343C),
                  size: 40,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(51),
                    Colors.black.withAlpha(51),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
