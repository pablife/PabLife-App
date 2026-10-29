import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/recovery_password_code_controller.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../shared/themes/app_colors.dart';

class RecoveryPasswordCodePage extends StatelessWidget {
  static const route = '/auth/recovery-password-code';

  const RecoveryPasswordCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<RecoveryPasswordCodeController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: controller.goBack,
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
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Image.asset(
                      'assets/pages/auth/auth_banner.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
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
                              'Digite o código',
                              fontSize: 32,
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
                              child: TextDefault(
                                'Enviamos um código de 6 dígitos para ${controller.email}',
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
                              labelText: 'Código de verificação',
                              hintText: 'Digite o código de 6 dígitos',
                              keyboardType: TextInputType.number,
                              controller: controller.codeController,
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'Nova senha',
                              hintText: 'Digite a nova senha',
                              obscureText: controller.obscurePassword,
                              controller: controller.passwordController,
                              enabled: !controller.isLoading,
                              suffixIcon: IconButton(
                                onPressed: controller.toggleObscurePassword,
                                icon: Icon(
                                  controller.obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.aquaText.withAlpha(150),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'Confirmar nova senha',
                              hintText: 'Digite a senha novamente',
                              obscureText: controller.obscureConfirmPassword,
                              controller: controller.confirmPasswordController,
                              enabled: !controller.isLoading,
                              suffixIcon: IconButton(
                                onPressed:
                                    controller.toggleObscureConfirmPassword,
                                icon: Icon(
                                  controller.obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.aquaText.withAlpha(150),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                              left: 32,
                            ),
                            child: EdgeButtonRounded(
                              text: 'Redefinir senha',
                              width: double.infinity,
                              onTap: controller.verifyCodeAndUpdatePassword,
                              isLoading: controller.isLoading,
                              side: EdgeSide.left,
                            ),
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
