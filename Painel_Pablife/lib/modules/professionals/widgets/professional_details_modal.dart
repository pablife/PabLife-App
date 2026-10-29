import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../infra/models/professional_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../../../widgets/design_system/confirm_dialog.dart';
import '../../../widgets/design_system/text_default.dart';
import '../professional_approval_page.dart';
import '../professionals_controller.dart';

class ProfessionalDetailsModal extends StatelessWidget {
  final ProfessionalModel professional;
  final UserModel user;

  const ProfessionalDetailsModal({
    super.key,
    required this.professional,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildUserDataSection(context),
              const SizedBox(height: 16),
              _buildProfessionalDataSection(context),
              const SizedBox(height: 16),
              _buildDocumentSection(context),
              const SizedBox(height: 16),
              _buildStatusHistorySection(context),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.primaryGreen,
          backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
              ? NetworkImage(user.imageUrl!)
              : null,
          child: user.imageUrl == null || user.imageUrl!.isEmpty
              ? Text(
                  user.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextDefault(
                text: user.fullName,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 4),
              TextDefault(
                text: user.email,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBadge(
                    _getProfessionalTypeText(professional.type),
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.primaryGreen,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    professional.validationStatus.displayName,
                    _getStatusColor(professional.validationStatus),
                    context,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: TextDefault(
        text: text,
        fontSize: 11,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.white
            : AppColors.primaryGreen,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUserDataSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Dados Pessoais',
      icon: Icons.person,
      children: [
        _buildDetailRow('Nome Completo', user.fullName),
        _buildDetailRow('Email', user.email),
        _buildDetailRow('Telefone', user.phone),
        _buildDetailRow('CPF', _formatCpf(user.cpfDocument)),
        _buildDetailRow(
          'Status Conta',
          user.status.displayName,
          color: user.status == UserStatus.active
              ? AppColors.success
              : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildProfessionalDataSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Dados Profissionais',
      icon: Icons.work,
      children: [
        _buildDetailRow(
          'Categoria',
          _getProfessionalTypeText(professional.type),
        ),
        _buildDetailRow(
          'Status Validação',
          professional.validationStatus.displayName,
          color: _getStatusColor(professional.validationStatus),
        ),
        _buildDetailRow('Cadastrado em', _formatDate(professional.createdAt)),
        _buildDetailRow('Atualizado em', _formatDate(professional.updatedAt)),
      ],
    );
  }

  Widget _buildDocumentSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Documentos Anexados',
      icon: Icons.attach_file,

      children: [
        if (professional.validationDocumentUrl != null &&
            professional.validationDocumentUrl!.isNotEmpty)
          InkWell(
            onTap: () => _openDocument(professional.validationDocumentUrl!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.primaryGreen,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextDefault(
                          text: 'Documento de Validação',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 2),
                        TextDefault(
                          text: 'Clique para visualizar ou baixar',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, color: AppColors.primaryGreen),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                SizedBox(width: 12),
                TextDefault(
                  text: 'Nenhum documento anexado',
                  fontSize: 14,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusHistorySection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Histórico de Status',
      icon: Icons.history,
      children: [
        _buildTimelineItem(
          'Conta criada',
          _formatDateTime(user.createdAt),
          Icons.person_add,
          AppColors.info,
        ),
        _buildTimelineItem(
          'Cadastro profissional',
          _formatDateTime(professional.createdAt),
          Icons.work,
          AppColors.primaryGreen,
        ),
        if (professional.validationStatus == ValidationStatus.approved)
          _buildTimelineItem(
            'Aprovado',
            _formatDateTime(professional.updatedAt),
            Icons.check_circle,
            AppColors.success,
          ),
        if (professional.validationStatus == ValidationStatus.rejected)
          _buildTimelineItem(
            'Rejeitado',
            _formatDateTime(professional.updatedAt),
            Icons.cancel,
            AppColors.error,
          ),
        if (professional.validationStatus == ValidationStatus.pending)
          _buildTimelineItem(
            'Aguardando aprovação',
            'Pendente',
            Icons.hourglass_empty,
            AppColors.warning,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextDefault(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              TextDefault(
                text: subtitle,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final controller = Get.find<ProfessionalsController>();
    final isActive = user.status == UserStatus.active;
    final isPendingOrRejected =
        professional.validationStatus == ValidationStatus.pending ||
        professional.validationStatus == ValidationStatus.rejected;

    return Column(
      children: [
        if (isPendingOrRejected)
          SizedBox(
            width: double.infinity,
            child: AppButtonDefault(
              text: 'Revisar Aprovação',
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  ProfessionalApprovalPage.route,
                  arguments: {'professional': professional, 'user': user},
                );
              },
              buttonColor: AppColors.primaryGreen,
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: AppButtonDefault(
              text: isActive ? 'Desativar Usuário' : 'Ativar Usuário',
              onTap: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: isActive
                      ? 'Desativar Profissional'
                      : 'Ativar Profissional',
                  message: isActive
                      ? 'Tem certeza que deseja desativar "${user.fullName}"?\n\nO profissional não poderá oferecer serviços enquanto estiver desativado.'
                      : 'Tem certeza que deseja ativar "${user.fullName}"?\n\nO profissional poderá oferecer serviços na plataforma.',
                  confirmText: isActive ? 'Desativar' : 'Ativar',
                  confirmColor: isActive
                      ? AppColors.warning
                      : AppColors.success,
                  icon: isActive ? Icons.person_off : Icons.person,
                );
                if (confirmed) {
                  await controller.toggleUserStatus(user.id!, user.status);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              buttonColor: isActive ? AppColors.warning : AppColors.success,
            ),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                TextDefault(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: TextDefault(
              text: label,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TextDefault(
              text: value,
              fontSize: 13,
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String _getProfessionalTypeText(String type) {
    switch (type) {
      case 'nutritionist':
        return 'Nutricionista';
      case 'psychologist':
        return 'Psicólogo(a)';
      default:
        return type;
    }
  }

  Color _getStatusColor(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return AppColors.warning;
      case ValidationStatus.approved:
        return AppColors.success;
      case ValidationStatus.rejected:
        return AppColors.error;
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
