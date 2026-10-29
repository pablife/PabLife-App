import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/text_default.dart';
import '../mentorship_controller.dart';
import '../widgets/mentorship_form_widgets.dart';

class LessonFormPage extends StatelessWidget {
  const LessonFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();
    final formKey = GlobalKey<FormState>();

    final args = Get.arguments as Map<String, dynamic>?;
    final moduleId = args?['moduleId'] as String?;
    final lessonId = args?['lessonId'] as String?;
    final mentorshipId =
        args?['mentorshipId'] as String?; // garantir que seja passado
    final isEdit = lessonId != null;

    // Inicializar formulário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEdit && args != null) {
        controller.initLessonForm(
          lessonId: lessonId,
          lessonNumber: args['lessonNumber'] as int?,
          title: args['title'] as String?,
          videoUrl: args['videoUrl'] as String?,
        );
      } else {
        controller.lessonTitleController.clear();
        controller.lessonVideoUrlController.clear();
        controller.lessonNumberController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Aula' : 'Nova Aula'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextDefault(
                text: 'Informações da Aula',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),

              AppTextFormField(
                controller: controller.lessonNumberController,
                title: 'Número da Aula',
                hintText: 'Ex: 1',
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

              AppTextFormField(
                controller: controller.lessonTitleController,
                title: 'Título da Aula',
                hintText: 'Digite o título',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: controller.lessonVideoUrlController,
                title: 'Link do Vídeo',
                hintText: 'URL do Vimeo ou YouTube',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              GetBuilder<MentorshipController>(
                builder: (_) {
                  return FormActions(
                    formKey: formKey,
                    onSave: () {
                      if (moduleId != null) {
                        controller.handleSaveLesson(
                          moduleId: moduleId,
                          lessonId: lessonId,
                          mentorshipId: mentorshipId,
                        );
                      } else {
                        AppSnackbar.to.error('Dados inválidos');
                      }
                    },
                    saveLabel: controller.isLoading
                        ? (isEdit ? 'Salvando...' : 'Criando...')
                        : (isEdit ? 'Salvar' : 'Criar'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
