import 'package:flutter/material.dart';
import '../../../infra/models/mentorship_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class MentorshipCardItem extends StatelessWidget {
  final MentorshipModel mentorship;
  final VoidCallback onTap;
  final Function(bool)? onToggleStatus;

  const MentorshipCardItem({
    super.key,
    required this.mentorship,
    required this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem ou ícone
            if (mentorship.imageUrl != null && mentorship.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  mentorship.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF9C27B0),
                      size: 64,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_outlined,
                    color: Color(0xFF9C27B0),
                    size: 64,
                  ),
                ),
              ),

            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextDefault(
                      text: mentorship.title,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Descrição
                    TextDefault(
                      text: mentorship.description,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    const Divider(height: 24),

                    // Informações
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        TextDefault(
                          text: '${mentorship.duration}h',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextDefault(
                            text: mentorship.author,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mentorship.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mentorship.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: mentorship.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              TextDefault(
                                text: mentorship.isActive ? 'Ativo' : 'Inativo',
                                fontSize: 12,
                                color: mentorship.isActive
                                    ? Colors.green[700]!
                                    : Colors.red[700]!,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                        if (onToggleStatus != null) ...[
                          const Spacer(),
                          Switch(
                            value: mentorship.isActive,
                            onChanged: onToggleStatus,
                            activeTrackColor: Colors.green,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botão
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Ver Detalhes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9C27B0),
                          side: const BorderSide(color: Color(0xFF9C27B0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
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
