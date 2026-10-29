import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/text_default.dart';
import '../mentorship_controller.dart';
import '../widgets/mentorship_form_widgets.dart';

class ModuleFormPage extends StatelessWidget {
  const ModuleFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();
    final formKey = GlobalKey<FormState>();

    final args = Get.arguments as Map<String, dynamic>?;
    final mentorshipId = args?['mentorshipId'] as String?;
    final moduleId = args?['moduleId'] as String?;
    final isEdit = moduleId != null;

    // Inicializar formulário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEdit && args != null) {
        controller.initModuleForm(moduleName: args['moduleName'] ?? '');
      } else {
        controller.moduleNameController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Módulo' : 'Novo Módulo'),
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
                text: 'Informações do Módulo',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),

              AppTextFormField(
                controller: controller.moduleNameController,
                title: 'Nome do Módulo',
                hintText: 'Ex: Introdução, Fundamentos, etc.',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              GetBuilder<MentorshipController>(
                builder: (controller) {
                  return FormActions(
                    formKey: formKey,
                    onSave: controller.isLoading
                        ? () {}
                        : () {
                            controller.handleSaveModule(
                              mentorshipId: mentorshipId,
                              moduleId: moduleId,
                            );
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
