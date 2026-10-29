import 'package:flutter/material.dart';

class BookmarkButtonWidget extends StatelessWidget {
  final bool isActive;
  final int savedCount;
  final VoidCallback onTap;

  const BookmarkButtonWidget({
    super.key,
    required this.isActive,
    required this.savedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              isActive ? Icons.bookmark : Icons.bookmark_outline,
              color: isActive
                  ? const Color(0xFF0C8DA1)
                  : const Color(0xFF00343C),
              size: 28,
            ),
          ),
        ),
        if (isActive)
          Positioned(
            top: -4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFF0C8DA1),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  savedCount.toString(),
                  style: const TextStyle(
                    color: Color(0xFFF3F3F3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Instrument Sans',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
