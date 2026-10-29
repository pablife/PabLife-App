import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/text_default.dart';
import '../mentorship_controller.dart';
import '../widgets/mentorship_form_widgets.dart';

class MentorshipEditPage extends StatelessWidget {
  const MentorshipEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();
    final formKey = GlobalKey<FormState>();
    final args = Get.arguments as Map<String, dynamic>?;

    if (args == null) {
      Get.back();
      return const SizedBox.shrink();
    }

    final mentorshipId = args['id'] as String;

    // Initialize form with existing data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.titleController.text = args['title'] ?? '';
      controller.authorController.text = args['author'] ?? '';
      controller.durationController.text = args['duration']?.toString() ?? '';
      controller.descriptionController.text = args['description'] ?? '';
      controller.selectedCategoryId = args['categoryId'];
      controller.imageUrl = args['imageUrl'];
      controller.uploadedImagePath = null;
      controller.update(); // Força atualização da UI
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Mentoria'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextDefault(
                text: 'Informações da Mentoria',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),

              AppTextFormField(
                controller: controller.titleController,
                title: 'Título',
                hintText: 'Digite o título da mentoria',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: controller.authorController,
                title: 'Autor',
                hintText: 'Nome do autor/instrutor',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: controller.durationController,
                title: 'Duração (em horas)',
                hintText: 'Ex: 10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Digite um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const CategoryDropdown(),
              const SizedBox(height: 16),

              // Upload de imagem
              GetBuilder<MentorshipController>(
                builder: (controller) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imagem da Mentoria',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Selecionar Imagem'),
                        onPressed: controller.isLoading
                            ? null
                            : () => controller.pickAndUploadImage(),
                      ),
                      if (controller.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Imagem carregada',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            controller.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 160,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: controller.descriptionController,
                title: 'Descrição',
                hintText: 'Descreva a mentoria',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              FormActions(
                formKey: formKey,
                onSave: () => controller.handleUpdateMentorship(mentorshipId),
                saveLabel: 'Salvar Alterações',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
