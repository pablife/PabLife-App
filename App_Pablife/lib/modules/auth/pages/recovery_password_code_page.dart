import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recovery_password_code_controller.dart';
import 'widgets/auth_animated_background.dart';
import 'widgets/auth_form_layout.dart';

/// "Confira seu e-mail" (canvas "Onb7", segundo estado): o código que chegou
/// por e-mail e a senha nova. Dá para pedir outro código.
class RecoveryPasswordCodePage extends StatelessWidget {
  static const route = '/auth/recovery-password-code';

  const RecoveryPasswordCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecoveryPasswordCodeController>(
      builder: (controller) {
        final busy = controller.isLoading;
        final ready =
            controller.codeController.text.trim().isNotEmpty &&
            controller.passwordController.text.isNotEmpty &&
            controller.confirmPasswordController.text.isNotEmpty;

        void submit() {
          if (busy) return;
          FocusScope.of(context).unfocus();
          controller.verifyCodeAndUpdatePassword();
        }

        Widget eye(bool hidden, VoidCallback onTap) => IconButton(
          tooltip: hidden ? 'Mostrar senha' : 'Ocultar senha',
          onPressed: onTap,
          icon: Icon(
            hidden ? Icons.visibility : Icons.visibility_off,
            color: AuthColors.hint,
          ),
        );

        return AuthFormLayout(
          title: 'Confira seu e-mail',
          subtitle: controller.email.isEmpty
              ? 'Enviamos um código de 6 dígitos. Digite o código e a '
                    'senha nova.'
              : 'Enviamos um código de 6 dígitos para ${controller.email}. '
                    'Digite o código e a senha nova.',
          field: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Código',
                hint: '6 dígitos',
                controller: controller.codeController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                onChanged: (_) => controller.update(),
                onSubmitted: (_) {},
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Senha nova',
                hint: 'Pelo menos 6 caracteres',
                controller: controller.passwordController,
                enabled: !busy,
                obscureText: controller.obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => controller.update(),
                onSubmitted: (_) {},
                suffix: eye(
                  controller.obscurePassword,
                  controller.toggleObscurePassword,
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Repita a senha nova',
                hint: 'Digite a senha de novo',
                controller: controller.confirmPasswordController,
                enabled: !busy,
                obscureText: controller.obscureConfirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => controller.update(),
                onSubmitted: (_) => submit(),
                suffix: eye(
                  controller.obscureConfirmPassword,
                  controller.toggleObscureConfirmPassword,
                ),
              ),
            ],
          ),
          footerText: 'Não chegou?',
          footerLink: controller.isResending
              ? 'Reenviando…'
              : 'Reenviar código',
          onFooterLink: controller.resendCode,
          button: AuthContinueButton(
            label: 'Salvar senha',
            enabled: ready && !busy,
            loading: busy,
            loadingLabel: 'Salvando…',
            onTap: submit,
          ),
        );
      },
    );
  }
}
