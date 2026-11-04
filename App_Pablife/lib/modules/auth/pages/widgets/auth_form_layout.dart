import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_animated_background.dart';

/// Desenho das telas de login: fundo animado, marca, ilustração e cartão.
class AuthFormLayout extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Campo(s) do formulário.
  final Widget field;

  /// Linha de baixo: texto com link à esquerda e botão à direita.
  final String footerText;
  final String footerLink;
  final VoidCallback onFooterLink;
  final Widget button;

  const AuthFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.field,
    required this.footerText,
    required this.footerLink,
    required this.onFooterLink,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Stack(
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
                      AuthEntrance(
                        from: -30,
                        delay: 100,
                        child: SizedBox(
                          width: math.min(400, constraints.maxWidth * .82),
                          child: const AuthFloatingArt(
                            asset: 'assets/pages/auth/login_art.png',
                            aspectRatio: 915 / 753,
                            description:
                                'Ilustração: busto clássico lilás com coroa, '
                                'jarro derramando carinhas sorridentes e vaso '
                                'com flor',
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -14),
                        child: AuthEntrance(
                          from: 60,
                          delay: 150,
                          child: _card(),
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
      ),
    );
  }

  Widget _card() {
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
              AuthEntrance(
                delay: 400,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                    color: AuthColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AuthEntrance(
                delay: 400,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AuthColors.muted),
                ),
              ),
              const SizedBox(height: 24),
              AuthEntrance(delay: 500, child: field),
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
                        Text(
                          footerText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AuthColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: onFooterLink,
                          child: Text(
                            footerLink,
                            style: const TextStyle(
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
                    button,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

/// Campo arredondado das telas de login.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String> autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Color borderColor;
  final Color focusedBorderColor;
  final Widget? suffix;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints = const [],
    this.focusNode,
    this.borderColor = Colors.transparent,
    this.focusedBorderColor = AuthColors.accent,
    this.suffix,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AuthColors.text,
            ),
          ),
        ),
        TextField(
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          autofillHints: autofillHints,
          autocorrect: false,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 16, color: AuthColors.text),
          cursorColor: AuthColors.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AuthColors.hint),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 18,
            ),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: suffix,
                  ),
            enabledBorder: border(borderColor),
            disabledBorder: border(borderColor),
            focusedBorder: border(focusedBorderColor),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
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

/// Botão "Continuar" com seta das telas de login.
class AuthContinueButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String loadingLabel;
  final VoidCallback onTap;

  const AuthContinueButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.loadingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFFFBFAFC);
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
                    loading ? loadingLabel : 'Continuar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
