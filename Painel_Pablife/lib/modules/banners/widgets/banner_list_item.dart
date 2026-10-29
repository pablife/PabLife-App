import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/banner_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

class BannerListItem extends StatelessWidget {
  final BannerModel banner;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BannerListItem({
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem ou ícone
            Flexible(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    banner.imageUrl,
                    height: 500,
                    // width: double.infinity,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.white.withValues(alpha: 0.1)
                            : AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.white
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Título
            TextDefault(
              text: banner.title,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Status com badge
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: banner.isActive && !isExpired
                        ? AppColors.success
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                TextDefault(
                  text: banner.isActive && !isExpired ? 'Ativo' : 'Inativo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: banner.isActive && !isExpired
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Data de expiração
            TextDefault(
              text: 'Expira em: ${_formatDate(expirationDate)}',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),

            // Link
            Row(
              children: [
                Icon(Icons.link, size: 20, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: TextDefault(
                    text: banner.linkUrl,
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Botões de ação
            Row(
              children: [
                // Botão Editar
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primaryGreen,
                    ),
                    label: TextDefault(text: 'Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.greyLight),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Botão Ativar/Desativar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onToggleActive(!banner.isActive),
                    icon: Icon(
                      banner.isActive ? Icons.close : Icons.check,
                      size: 16,
                    ),
                    label: Text(
                      banner.isActive ? 'Desativar' : 'Ativar',
                      style: const TextStyle(fontSize: 17),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: banner.isActive
                          ? AppColors.error
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Botão Excluir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Excluir', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
