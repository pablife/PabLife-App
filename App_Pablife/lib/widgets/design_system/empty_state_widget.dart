import 'package:flutter/material.dart';
import 'text_default.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final double iconSize;
  final Color? iconColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color? titleColor;
  final double? descriptionFontSize;
  final FontWeight? descriptionFontWeight;
  final Color? descriptionColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.iconSize = 64,
    this.iconColor,
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w600,
    this.titleColor,
    this.descriptionFontSize = 14,
    this.descriptionFontWeight = FontWeight.w400,
    this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? const Color(0xFF00343C).withAlpha(128),
            ),
            const SizedBox(height: 16),
            TextDefault(
              title,
              fontSize: titleFontSize,
              fontWeight: titleFontWeight,
              color: titleColor ?? const Color(0xFF00343C).withAlpha(128),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              TextDefault(
                description!,
                fontSize: descriptionFontSize,
                fontWeight: descriptionFontWeight,
                color:
                    descriptionColor ?? const Color(0xFF00343C).withAlpha(102),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
