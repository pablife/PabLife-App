import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:brasil_fields/brasil_fields.dart';
import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/profile_avatar_widget.dart';
import '../../../widgets/design_system/notification_button_widget.dart';
import '../profile_controller.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  static const route = '/profile/edit';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        if (controller.isLoading && controller.currentUser == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF00343C),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = controller.currentUser;
        if (user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF00343C),
            body: Center(
              child: Text(
                'Erro ao carregar perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          resizeToAvoidBottomInset: true,
          appBar: AppBarDefault(
            title: 'Editar Perfil',
            trailing: const NotificationButtonWidget(),
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: ProfileAvatarWidget(
                  imageUrl: user.imageUrl,
                  onEditTap: controller.editProfilePhoto,
                  isLoading: controller.isLoading,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                AppTextFormField(
                                  hintText: 'Nome Completo',
                                  controller: controller.fullNameController,
                                  enabled: !controller.isLoading,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nome completo é obrigatório';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                AppTextFormField(
                                  hintText: 'E-mail',
                                  keyboardType: TextInputType.emailAddress,
                                  controller: controller.emailController,
                                  enabled: false,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'E-mail é obrigatório';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'E-mail inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                AppTextFormField(
                                  hintText: 'Telefone',
                                  keyboardType: TextInputType.number,
                                  controller: controller.phoneController,
                                  enabled: !controller.isLoading,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    TelefoneInputFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Telefone é obrigatório';
                                    }
                                    final digitsOnly = value.replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    );
                                    if (digitsOnly.length < 10 ||
                                        digitsOnly.length > 11) {
                                      return 'Telefone inválido';
                                    }
                                    return null;
                                  },
                                ),
                                if (user.role.value == 'professional') ...[
                                  const SizedBox(height: 15),
                                  AppTextFormField(
                                    hintText: 'Descrição',
                                    controller:
                                        controller.descriptionController,
                                    enabled: !controller.isLoading,
                                    maxLines: 4,
                                    validator: (value) {
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: EdgeButtonRounded(
                                  text: 'Cancelar',
                                  onTap: controller.isLoading
                                      ? null
                                      : () => Get.back(),
                                  backgroundColor: const Color(0xFF0C8DA1),
                                  side: EdgeSide.right,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: EdgeButtonRounded(
                                  text: 'Salvar',
                                  onTap: controller.isLoading
                                      ? null
                                      : controller.saveProfile,
                                  backgroundColor: const Color(0xFF00343C),
                                  side: EdgeSide.left,
                                  isLoading: controller.isLoading,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
