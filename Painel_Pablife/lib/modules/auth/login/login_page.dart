import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../shared/utils/app_assets.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/text_default.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GetBuilder<LoginController>(
        builder: (controller) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Título
                      Image.asset(AppAssets.appLogoPng, height: 100),
                      const SizedBox(height: 24),
                      const TextDefault(
                        text: 'Painel Administrativo',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 8),
                      const TextDefault(
                        text: 'PabLife',
                        fontSize: 16,
                        textAlign: TextAlign.center,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 48),

                      // Campo E-mail
                      AppTextFormField(
                        controller: controller.emailController,
                        title: 'E-mail',
                        hintText: 'Digite seu e-mail',
                        keyboardType: TextInputType.emailAddress,
                        validator: controller.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Campo Senha
                      AppTextFormField(
                        controller: controller.passwordController,
                        title: 'Senha',
                        hintText: 'Digite sua senha',
                        obscureText: controller.obscurePassword,
                        validator: controller.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Esqueci minha senha
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: controller.isLoading
                              ? null
                              : controller.forgotPassword,
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão Entrar
                      AppButtonDefault(
                        text: 'Entrar',
                        onTap: controller.signIn,
                        isLoading: controller.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Aviso
                      const TextDefault(
                        text:
                            'Apenas administradores podem acessar este painel',
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        color: AppColors.textSecondary,
                      ),
                      
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          return TextDefault(
                            text:
                                'Versão: ${snapshot.data?.version}+${snapshot.data?.buildNumber}',
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            color: AppColors.textSecondary,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
