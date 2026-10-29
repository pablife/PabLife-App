import 'package:flutter/material.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../../../widgets/design_system/confirm_dialog.dart';
import '../../../widgets/design_system/text_default.dart';

class UserDetailsModal extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggleStatus;

  const UserDetailsModal({
    super.key,
    required this.user,
    required this.onToggleStatus,
  });

  Future<void> _confirmToggleStatus(BuildContext context) async {
    final isActive = user.status == UserStatus.active;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: isActive ? 'Desativar Usuário' : 'Ativar Usuário',
      message: isActive
          ? 'Tem certeza que deseja desativar "${user.fullName}"?\n\nO usuário não poderá acessar a plataforma enquanto estiver desativado.'
          : 'Tem certeza que deseja ativar "${user.fullName}"?\n\nO usuário poderá acessar a plataforma normalmente.',
      confirmText: isActive ? 'Desativar' : 'Ativar',
      confirmColor: isActive ? AppColors.warning : AppColors.success,
      icon: isActive ? Icons.person_off : Icons.person,
    );

    if (confirmed) {
      onToggleStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextDefault(
                        text: user.fullName,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 4),
                      TextDefault(
                        text: user.email,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Telefone', user.phone),
            _buildDetailRow('CPF', user.cpfDocument),
            _buildDetailRow(
              'Status',
              user.status.displayName,
              color: user.status == UserStatus.active
                  ? AppColors.success
                  : AppColors.warning,
            ),
            _buildDetailRow('Data de Criação', _formatDate(user.createdAt)),
            _buildDetailRow(
              'Termos Aceitos',
              user.termsAccepted ? 'Sim' : 'Não',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (context) => AppButtonDefault(
                  text: user.status == UserStatus.active
                      ? 'Desativar Usuário'
                      : 'Ativar Usuário',
                  onTap: () => _confirmToggleStatus(context),
                  buttonColor: user.status == UserStatus.active
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextDefault(
            text: label,
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          TextDefault(
            text: value,
            fontSize: 14,
            color: color ?? AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
