import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../infra/models/professional_model.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../shared/themes/app_colors.dart';
import '../../shared/utils/app_assets.dart';
import '../../widgets/design_system/app_button_default.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/states/app_widget_loading.dart';

class ProfessionalsPendingPage extends StatefulWidget {
  const ProfessionalsPendingPage({super.key});

  static const route = '/professionals/pending';

  @override
  State<ProfessionalsPendingPage> createState() =>
      _ProfessionalsPendingPageState();
}

class _ProfessionalsPendingPageState extends State<ProfessionalsPendingPage> {
  final ProfessionalRepository _repository = ProfessionalRepository();
  List<ProfessionalModel> pendingProfessionals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final response = await _repository.getPendingProfessionals();
      setState(() {
        pendingProfessionals = response.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao carregar profissionais: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _approveProfessional(ProfessionalModel prof) async {
    try {
      await _repository.updateValidationStatus(
        prof.id,
        ValidationStatus.approved,
      );
      Get.snackbar('Sucesso', 'Profissional aprovado');
      await _loadPending();
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao aprovar profissional: $e');
    }
  }

  Future<void> _rejectProfessional(ProfessionalModel prof) async {
    try {
      await _repository.updateValidationStatus(
        prof.id,
        ValidationStatus.rejected,
      );
      Get.snackbar('Sucesso', 'Profissional rejeitado');
      await _loadPending();
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao rejeitar profissional: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(AppAssets.appLogoPng, height: 28),
            const SizedBox(width: 12),
            const Text('Aprovar Profissionais'),
          ],
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const AppWidgetLoading()
          : pendingProfessionals.isEmpty
          ? Center(
              child: TextDefault(
                text: 'Nenhum profissional pendente',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            )
          : ListView.builder(
              itemCount: pendingProfessionals.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final prof = pendingProfessionals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextDefault(
                          text: 'ID: ${prof.id}',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 8),
                        TextDefault(
                          text: 'Tipo: ${prof.type}',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButtonDefault(
                                text: 'Aprovar',
                                onTap: () => _approveProfessional(prof),
                                buttonColor: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButtonDefault(
                                text: 'Rejeitar',
                                onTap: () => _rejectProfessional(prof),
                                buttonColor: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
