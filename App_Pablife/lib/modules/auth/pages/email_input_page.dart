import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/modules/auth/pages/sign_up_page.dart';

import '../controllers/email_input_controller.dart';
import 'widgets/auth_animated_background.dart';

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
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: GetBuilder<EmailInputController>(
        builder: (controller) {
          final showError =
              _touched &&
              controller.email.isNotEmpty &&
              !controller.isEmailValid;

          return Stack(
            children: [
              const Positioned.fill(child: AuthAnimatedBackground()),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          const AuthEntrance(from: -30, child: _Brand()),
                          const SizedBox(height: 16),
                          _Illustration(maxWidth: constraints.maxWidth),
                          Transform.translate(
                            offset: const Offset(0, -14),
                            child: AuthEntrance(
                              from: 60,
                              delay: 150,
                              child: _form(controller, showError),
                            ),
                          ),
                          const SizedBox(height: 34),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _form(EmailInputController controller, bool showError) {
    final canSubmit = controller.isEmailValid && !controller.isLoading;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
          decoration: BoxDecoration(
            color: AuthColors.panel,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 80,
                spreadRadius: -30,
                offset: Offset(0, 40),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthEntrance(
                delay: 400,
                child: Text(
                  'Digite seu e-mail',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                    color: AuthColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const AuthEntrance(
                delay: 400,
                child: Text(
                  'Informe o e-mail da sua conta para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AuthColors.muted),
                ),
              ),
              const SizedBox(height: 24),
              AuthEntrance(
                delay: 500,
                child: _emailField(controller, showError),
              ),
              const SizedBox(height: 28),
              AuthEntrance(
                delay: 600,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Não tem conta?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AuthColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => Get.toNamed(SignUpPage.route),
                          child: const Text(
                            'Cadastrar agora',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AuthColors.text,
                              decoration: TextDecoration.underline,
                              decorationColor: AuthColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _ContinueButton(
                      enabled: canSubmit,
                      loading: controller.isLoading,
                      onTap: () => _submit(controller),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailField(EmailInputController controller, bool showError) {
    final borderColor = showError
        ? AuthColors.errorBorder
        : controller.isEmailValid
        ? AuthColors.accent
        : Colors.transparent;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'E-mail',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AuthColors.text,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(math.sin(_shake.value * math.pi * 4) * 6, 0),
            child: child,
          ),
          child: TextField(
            focusNode: _focus,
            enabled: !controller.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onChanged: controller.updateEmail,
            onSubmitted: (_) => _submit(controller),
            style: const TextStyle(fontSize: 16, color: AuthColors.text),
            cursorColor: AuthColors.text,
            decoration: InputDecoration(
              hintText: 'seuemail@exemplo.com',
              hintStyle: const TextStyle(color: AuthColors.hint),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              enabledBorder: border(borderColor),
              disabledBorder: border(borderColor),
              focusedBorder: border(
                showError ? AuthColors.errorBorder : AuthColors.accent,
              ),
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 8),
            child: Text(
              'Digite um e-mail válido, como nome@exemplo.com',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AuthColors.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(
            text: 'pab',
            style: TextStyle(color: AuthColors.brandPink),
          ),
          TextSpan(
            text: 'life',
            style: TextStyle(color: AuthColors.accent),
          ),
        ],
      ),
      semanticsLabel: 'PabLife',
      style: const TextStyle(
        fontSize: 40,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final double maxWidth;

  const _Illustration({required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return AuthEntrance(
      from: -30,
      delay: 100,
      child: SizedBox(
        width: math.min(400, maxWidth * .82),
        child: const AuthFloatingArt(
          asset: 'assets/pages/auth/login_art.png',
          aspectRatio: 915 / 753,
          description:
              'Ilustração: busto clássico lilás com coroa, jarro derramando '
              'carinhas sorridentes e vaso com flor',
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || loading ? 1 : .45,
      child: Material(
        color: AuthColors.text,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loading ? 'Verificando…' : 'Continuar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFBFAFC),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Color(0xFFFBFAFC),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
