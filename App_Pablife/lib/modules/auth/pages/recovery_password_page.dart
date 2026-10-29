import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/recovery_password_controller.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../shared/themes/app_colors.dart';

class RecoveryPasswordPage extends StatelessWidget {
  const RecoveryPasswordPage({super.key});

  static const route = '/auth/recovery-password';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<RecoveryPasswordController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: controller.goToLogin,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.white.withAlpha(80),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AppTextVector(width: 147, height: 45),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 32,
                              top: 32,
                            ),
                            child: const TextDefault(
                              'Esqueceu sua senha?',
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
                                'Digite o e-mail cadastrado para receber o link de redefinição',
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
                              hintText: 'Digite seu e-mail',
                              initialValue: controller.email,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: controller.updateEmail,
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(height: 32),
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
                                          'Voltar ao',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        TextButton(
                                          onPressed: controller.goToLogin,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const TextDefault(
                                            'Login',
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: EdgeButtonRounded(
                                  text: 'Enviar E-mail',
                                  width: 190,
                                  onTap: controller.sendRecoveryLink,
                                  isLoading: controller.isLoading,
                                  side: EdgeSide.left,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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
