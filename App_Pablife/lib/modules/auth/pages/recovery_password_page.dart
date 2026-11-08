import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recovery_password_controller.dart';
import 'widgets/auth_form_layout.dart';

/// Recuperar senha (canvas "Onb7"): e-mail da conta e "Enviar código".
class RecoveryPasswordPage extends StatefulWidget {
  const RecoveryPasswordPage({super.key});

  static const route = '/auth/recovery-password';

  @override
  State<RecoveryPasswordPage> createState() => _RecoveryPasswordPageState();
}

class _RecoveryPasswordPageState extends State<RecoveryPasswordPage> {
  late final _email = TextEditingController(
    text: Get.find<RecoveryPasswordController>().email,
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecoveryPasswordController>(
      builder: (controller) {
        void submit() {
          if (controller.isLoading) return;
          FocusScope.of(context).unfocus();
          controller.sendRecoveryLink();
        }

        return AuthFormLayout(
          title: 'Esqueceu sua senha?',
          subtitle:
              'Digite o e-mail da sua conta. Enviamos um código para você '
              'criar uma senha nova.',
          field: AuthTextField(
            label: 'E-mail',
            hint: 'seuemail@exemplo.com',
            controller: _email,
            enabled: !controller.isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: controller.updateEmail,
            onSubmitted: (_) => submit(),
          ),
          footerText: 'Lembrou a senha?',
          footerLink: 'Voltar ao login',
          onFooterLink: controller.goToLogin,
          button: AuthContinueButton(
            label: 'Enviar código',
            enabled:
                controller.email.trim().isNotEmpty && !controller.isLoading,
            loading: controller.isLoading,
            loadingLabel: 'Enviando…',
            onTap: submit,
          ),
        );
      },
    );
  }
}
