import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/modules/auth/pages/sign_up_page.dart';

import '../controllers/email_input_controller.dart';
import 'widgets/auth_animated_background.dart';
import 'widgets/auth_form_layout.dart';

class EmailInputPage extends StatefulWidget {
  const EmailInputPage({super.key});

  static const route = '/auth/email';

  @override
  State<EmailInputPage> createState() => _EmailInputPageState();
}

class _EmailInputPageState extends State<EmailInputPage>
    with SingleTickerProviderStateMixin {
  bool _touched = false;
  final _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _touched = true);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _submit(EmailInputController controller) {
    if (controller.isLoading) return;
    if (!controller.isEmailValid) {
      setState(() => _touched = true);
      _shake.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();
    controller.checkEmail();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailInputController>(
      builder: (controller) {
        final showError =
            _touched && controller.email.isNotEmpty && !controller.isEmailValid;

        return AuthFormLayout(
          title: 'Digite seu e-mail',
          subtitle: 'Informe o e-mail da sua conta para continuar',
          field: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(math.sin(_shake.value * math.pi * 4) * 6, 0),
              child: child,
            ),
            child: AuthTextField(
              label: 'E-mail',
              hint: 'seuemail@exemplo.com',
              focusNode: _focus,
              enabled: !controller.isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: controller.updateEmail,
              onSubmitted: (_) => _submit(controller),
              borderColor: showError
                  ? AuthColors.errorBorder
                  : controller.isEmailValid
                  ? AuthColors.accent
                  : Colors.transparent,
              focusedBorderColor: showError
                  ? AuthColors.errorBorder
                  : AuthColors.accent,
              errorText: showError
                  ? 'Digite um e-mail válido, como nome@exemplo.com'
                  : null,
            ),
          ),
          footerText: 'Não tem conta?',
          footerLink: 'Cadastrar agora',
          onFooterLink: () => Get.toNamed(SignUpPage.route),
          button: AuthContinueButton(
            enabled: controller.isEmailValid && !controller.isLoading,
            loading: controller.isLoading,
            loadingLabel: 'Verificando…',
            onTap: () => _submit(controller),
          ),
        );
      },
    );
  }
}
