import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/password_controller.dart';
import 'widgets/auth_animated_background.dart';
import 'widgets/auth_form_layout.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  static const route = '/auth/password';

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  bool _showPassword = false;

  void _submit(PasswordController controller) {
    if (controller.isLoading) return;
    FocusScope.of(context).unfocus();
    controller.signIn();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PasswordController>(
      builder: (controller) {
        return AuthFormLayout(
          title: 'Digite sua senha',
          subtitle: 'Agora insira sua senha para acessar sua conta.',
          field: AuthTextField(
            label: 'Senha',
            hint: 'Digite sua senha',
            enabled: !controller.isLoading,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            onChanged: controller.updatePassword,
            onSubmitted: (_) => _submit(controller),
            suffix: IconButton(
              tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: AuthColors.hint,
              ),
            ),
          ),
          footerText: 'Esqueceu sua senha?',
          footerLink: 'Recuperar senha',
          onFooterLink: controller.forgotPassword,
          button: AuthContinueButton(
            enabled: controller.password.isNotEmpty && !controller.isLoading,
            loading: controller.isLoading,
            loadingLabel: 'Entrando…',
            onTap: () => _submit(controller),
          ),
        );
      },
    );
  }
}
