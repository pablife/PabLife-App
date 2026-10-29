import 'package:flutter/material.dart';
import 'app_image.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onEditTap;
  final bool isLoading;

  const ProfileAvatarWidget({
    super.key,
    this.imageUrl,
    this.onEditTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      height: 135,
      child: Stack(
        children: [
          AppImage(
            imageUrl: imageUrl,
            width: 135,
            height: 135,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(67.5),
            errorWidget: Container(
              width: 135,
              height: 135,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF89BEC6),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          if (onEditTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: isLoading ? null : onEditTap,
                child: Opacity(
                  opacity: isLoading ? 0.6 : 1.0,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3395),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
