import 'package:flutter/material.dart';
import '../../shared/themes/app_colors.dart';
import '../design_system/text_default.dart';

class AppWidgetEmpty extends StatelessWidget {
  const AppWidgetEmpty({
    super.key,
    required this.message,
    this.description = '',
  });

  final String message;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.greyDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          TextDefault(
            text: message,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextDefault(
              text: description,
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
