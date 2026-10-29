import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/password_controller.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../shared/themes/app_colors.dart';

class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});

  static const route = '/auth/password';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<PasswordController>(
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
                            'Digite sua senha',
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
                              'Agora insira sua senha para acessar sua conta.',
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
                            labelText: 'Senha',
                            hintText: 'Digite sua senha',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onChanged: controller.updatePassword,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              if (!controller.isLoading) {
                                controller.signIn();
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
                                padding: const EdgeInsets.only(left: 16),
                                child: Opacity(
                                  opacity: 0.56,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const TextDefault(
                                        'Esqueceu sua senha?',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      TextButton(
                                        onPressed: controller.forgotPassword,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const TextDefault(
                                          'Recuperar senha',
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
                                width: 170,
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  controller.signIn();
                                },
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
