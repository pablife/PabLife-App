import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../infra/models/professional_model.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../shared/themes/app_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/design_system/app_button_default.dart';
import '../../widgets/design_system/text_default.dart';
import 'professionals_controller.dart';

class ProfessionalApprovalPage extends StatelessWidget {
  const ProfessionalApprovalPage({super.key});

  static const route = '/professionals/approval';

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final professional = args['professional'] as ProfessionalModel;
    final user = args['user'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovação de Profissional'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextDefault(
                    text: user.fullName,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  TextDefault(
                    text: user.email,
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Dados do Usuário
            const TextDefault(
              text: 'Dados do Usuário',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Nome Completo', user.fullName),
                    const Divider(),
                    _buildInfoRow('Email', user.email),
                    const Divider(),
                    _buildInfoRow('Telefone', user.phone),
                    const Divider(),
                    _buildInfoRow('CPF', user.cpfDocument),
                    const Divider(),
                    _buildInfoRow(
                      'Status',
                      user.status == 'active' ? 'Ativo' : 'Inativo',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Dados Profissionais
            const TextDefault(
              text: 'Dados Profissionais',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Tipo',
                      _getProfessionalTypeText(professional.type),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Data de Cadastro',
                      _formatDate(professional.createdAt),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Status de Validação',
                      _getStatusText(professional.validationStatus),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Documento Comprovante
            const TextDefault(
              text: 'Documento Comprovante',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            if (professional.validationDocumentUrl != null)
              Card(
                child: InkWell(
                  onTap: () =>
                      _openDocument(professional.validationDocumentUrl!),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 32,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TextDefault(
                                text: 'Documento anexado',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              TextDefault(
                                text: 'Clique para visualizar',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.warning),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextDefault(
                          text: 'Nenhum documento anexado',
                          fontSize: 14,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Botões de Ação
            if (professional.validationStatus == ValidationStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButtonDefault(
                      text: 'Rejeitar',
                      onTap: () => _showRejectDialog(context, professional),
                      buttonColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButtonDefault(
                      text: 'Aprovar',
                      onTap: () => _showApproveDialog(context, professional),
                      buttonColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    professional.validationStatus,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      professional.validationStatus == ValidationStatus.approved
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _getStatusColor(professional.validationStatus),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextDefault(
                        text:
                            professional.validationStatus ==
                                ValidationStatus.approved
                            ? 'Este profissional já foi aprovado'
                            : 'Este profissional foi rejeitado',
                        fontSize: 16,
                        color: _getStatusColor(professional.validationStatus),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: TextDefault(
              text: label,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TextDefault(
              text: value,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getProfessionalTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'nutritionist':
        return 'Nutricionista';
      case 'psychologist':
        return 'Psicólogo';
      default:
        return type;
    }
  }

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
        return AppColors.warning;
      case ValidationStatus.approved:
        return AppColors.success;
      case ValidationStatus.rejected:
        return AppColors.error;
    }
  }

  void _openDocument(String url) {
    Get.snackbar(
      'Documento',
      'Abrindo documento em nova aba',
      duration: const Duration(seconds: 2),
    );
    // Aqui você pode usar url_launcher para abrir o documento
    // launch(url);
  }

  void _showApproveDialog(
    BuildContext context,
    ProfessionalModel professional,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aprovar Profissional'),
          content: const Text(
            'Tem certeza que deseja aprovar este profissional? '
            'Ele poderá oferecer serviços na plataforma.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _approveProfessional(professional);
              },
              child: const Text(
                'Aprovar',
                style: TextStyle(color: AppColors.success),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, ProfessionalModel professional) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rejeitar Profissional'),
          content: const Text(
            'Tem certeza que deseja rejeitar este profissional? '
            'Esta ação pode ser revertida posteriormente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _rejectProfessional(professional);
              },
              child: const Text(
                'Rejeitar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveProfessional(ProfessionalModel professional) async {
    try {
      final repository = ProfessionalRepository();
      await repository.updateValidationStatus(
        professional.id,
        ValidationStatus.approved,
      );
      // Atualiza a lista de profissionais antes de voltar
      if (Get.isRegistered<ProfessionalsController>()) {
        Get.find<ProfessionalsController>().loadProfessionals();
      }
      // Volta primeiro, depois mostra o snackbar na página anterior
      Get.back();
      AppSnackbar.to.success('Profissional aprovado com sucesso!');
    } catch (e) {
      AppSnackbar.to.error('Falha ao aprovar profissional: $e');
    }
  }

  Future<void> _rejectProfessional(ProfessionalModel professional) async {
    try {
      final repository = ProfessionalRepository();
      await repository.updateValidationStatus(
        professional.id,
        ValidationStatus.rejected,
      );
      // Atualiza a lista de profissionais antes de voltar
      if (Get.isRegistered<ProfessionalsController>()) {
        Get.find<ProfessionalsController>().loadProfessionals();
      }
      // Volta primeiro, depois mostra o snackbar na página anterior
      Get.back();
      AppSnackbar.to.success('Profissional rejeitado');
    } catch (e) {
      AppSnackbar.to.error('Falha ao rejeitar profissional: $e');
    }
  }
}
