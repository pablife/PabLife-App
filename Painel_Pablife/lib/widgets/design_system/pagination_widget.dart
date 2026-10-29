import 'package:flutter/material.dart';

import '../../shared/themes/app_colors.dart';
import 'text_default.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Function(int)? onPageSelected;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
  });

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage => currentPage < totalPages;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? theme.dividerColor.withValues(alpha: 0.3)
                : AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botão anterior
          IconButton(
            onPressed: hasPreviousPage ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            color: hasPreviousPage
                ? AppColors.primaryGreen
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),

          // Indicador de página
          TextDefault(
            text: 'Página $currentPage de $totalPages',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),

          // Botão próximo
          IconButton(
            onPressed: hasNextPage ? onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: hasNextPage
                ? AppColors.primaryGreen
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
