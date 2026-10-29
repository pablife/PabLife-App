import 'package:flutter/material.dart';
import '../../../infra/models/professional_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class ProfessionalListItem extends StatelessWidget {
  final ProfessionalModel professional;
  final UserModel? user;
  final VoidCallback onTap;
  final VoidCallback? onToggleStatus;

  const ProfessionalListItem({
    super.key,
    required this.professional,
    this.user,
    required this.onTap,
    this.onToggleStatus,
  });

  Color _getStatusColor() {
    if (professional.validationStatus == ValidationStatus.pending) {
      return Colors.orange;
    }
    if (professional.validationStatus == ValidationStatus.rejected) {
      return Colors.red;
    }
    if (user?.status == UserStatus.active) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText() {
    if (professional.validationStatus == ValidationStatus.pending) {
      return 'Pendente Validação';
    }
    if (professional.validationStatus == ValidationStatus.rejected) {
      return 'Rejeitado';
    }
    if (user?.status == UserStatus.active) return 'Ativo';
    return 'Inativo';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.primaryGreen.withValues(alpha: 0.1),
          child: user?.imageUrl != null && user!.imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    user!.imageUrl!,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primaryGreen,
                      size: 30,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.primaryGreen,
                  size: 30,
                ),
        ),
        title: TextDefault(
          text: user?.fullName ?? 'Sem nome',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TextDefault(
              text: user?.email ?? 'Sem email',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextDefault(
                    text: professional.type,
                    fontSize: 12,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextDefault(
                    text: _getStatusText(),
                    fontSize: 12,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (professional.validationStatus == ValidationStatus.approved &&
                user != null)
              IconButton(
                icon: Icon(
                  user!.status == UserStatus.active
                      ? Icons.toggle_on
                      : Icons.toggle_off,
                  color: user!.status == UserStatus.active
                      ? Colors.green
                      : Colors.grey,
                ),
                onPressed: onToggleStatus,
                tooltip: user!.status == UserStatus.active
                    ? 'Desativar'
                    : 'Ativar',
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
