import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/modules/auth/pages/sign_up_page.dart';
import 'package:pablife/widgets/app_text_vector.dart';
import '../controllers/email_input_controller.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../shared/themes/app_colors.dart';

class EmailInputPage extends StatelessWidget {
  const EmailInputPage({super.key});

  static const route = '/auth/email';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<EmailInputController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: AppTextVector(width: 147, height: 45)),
                ),
                Expanded(
                  flex: 3,
                  child: Image.asset(
                    'assets/pages/auth/auth_banner.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.second,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                            right: 32,
                            top: 32,
                          ),
                          child: const TextDefault(
                            'Digite seu e-mail',
                            fontSize: 36,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w700,
                            color: AppColors.aquaText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Opacity(
                            opacity: 0.56,
                            child: const TextDefault(
                              'Informe o e-mail da sua conta para continuar',
                              fontSize: 16,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AppTextFormField(
                            labelText: 'E-mail',
                            hintText: 'seu@email.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onChanged: controller.updateEmail,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              if (!controller.isLoading) {
                                controller.checkEmail();
                              }
                            },
                            enabled: !controller.isLoading,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Opacity(
                                  opacity: 0.56,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const TextDefault(
                                        'Não tem conta?',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Get.toNamed(SignUpPage.route),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const TextDefault(
                                          'Cadastrar agora',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: EdgeButtonRounded(
                                text: 'Continuar',
                                width: 190,
                                onTap: controller.checkEmail,
                                isLoading: controller.isLoading,
                                side: EdgeSide.left,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
