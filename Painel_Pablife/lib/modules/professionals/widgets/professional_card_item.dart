import 'package:flutter/material.dart';
import '../../../infra/models/professional_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class ProfessionalCardItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const ProfessionalCardItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _getStatusText(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return 'Pendente';
      case ValidationStatus.approved:
        return 'Aprovado';
      case ValidationStatus.rejected:
        return 'Rejeitado';
    }
  }

  Color _getStatusColor(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return Colors.orange;
      case ValidationStatus.approved:
        return Colors.green;
      case ValidationStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final professional = item['professional'] as ProfessionalModel;
    final user = item['user'];
    final statusColor = _getStatusColor(professional.validationStatus);

    return Card(
      elevation: professional.validationStatus == ValidationStatus.pending
          ? 3
          : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  user.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nome
              TextDefault(
                text: user.fullName,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Email
              TextDefault(
                text: user.email,
                fontSize: 12,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Tipo Profissional
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color.fromARGB(255, 83, 121, 89)
                      : const Color.fromARGB(255, 207, 219, 221),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextDefault(
                  text: professional.type,
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextDefault(
                      text: _getStatusText(professional.validationStatus),
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Botão de visualizar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text(
                    'Ver Detalhes',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.primaryGreen,
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primaryGreen,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
