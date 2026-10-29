import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../infra/models/mentorship_model.dart';
import '../../mentorship_controller.dart';

class MentorshipInfoCard extends StatelessWidget {
  const MentorshipInfoCard({super.key, required this.mentorship});

  final MentorshipModel mentorship;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextDefault(
              text: mentorship.title,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            TextDefault(
              text: 'Autor: ${mentorship.author}',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            TextDefault(
              text: 'Duração: ${mentorship.duration}h',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            TextDefault(
              text: 'Categoria: ${mentorship.categoryName ?? "N/A"}',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            TextDefault(
              text: mentorship.description,
              fontSize: 14,
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            if (mentorship.imageUrl != null && mentorship.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mentorship.imageUrl!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            // Ações: desativar (apenas botão) e excluir (com confirmação)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed:
                      null, // desativação não implementada, apenas o botão
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Desativar Curso'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir mentoria?'),
                        content: const Text(
                          'Esta ação não pode ser desfeita. Deseja realmente excluir o curso?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final controller = Get.find<MentorshipController>();
                      final ok = await controller.deleteMentorship(
                        mentorship.id,
                      );
                      if (ok) {
                        Get.back(closeOverlays: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir Curso'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
