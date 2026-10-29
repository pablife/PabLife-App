import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/banner_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

class BannerListRow extends StatelessWidget {
  final BannerModel banner;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BannerListRow({
    super.key,
    required this.banner,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final expirationDate = banner.createdAt.add(const Duration(days: 365));
    final isExpired = DateTime.now().isAfter(expirationDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 500;
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    banner.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isSmall ? constraints.maxWidth - 112 : 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextDefault(
                        text: banner.title,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: banner.isActive && !isExpired
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextDefault(
                            text: banner.isActive && !isExpired
                                ? 'Ativo'
                                : 'Inativo',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: banner.isActive && !isExpired
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 16),
                          TextDefault(
                            text: 'Expira em: ${_formatDate(expirationDate)}',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 20,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextDefault(
                              text: banner.linkUrl,
                              fontSize: 16,
                              color: AppColors.info,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(
                        banner.isActive ? Icons.close : Icons.check,
                        color: banner.isActive
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      onPressed: () => onToggleActive(!banner.isActive),
                      tooltip: banner.isActive ? 'Desativar' : 'Ativar',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
