import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/app_palette.dart';
import '../../onboarding/onboarding_page.dart';
import '../../onboarding/widgets/onboarding_background.dart';
import '../entry_visual.dart';
import 'choose_profile_page.dart';
import 'email_input_page.dart';
import 'widgets/auth_animated_background.dart';

/// Tela 4b do canvas: "Como você quer usar a Pablife?". Vem depois de
/// "Você é?" e antes do e-mail. A figura e as cores trocam na hora, para a
/// pessoa ver como o app vai ficar.
class VisualChoicePage extends StatefulWidget {
  const VisualChoicePage({super.key});

  static const route = '/choose-visual';

  @override
  State<VisualChoicePage> createState() => _VisualChoicePageState();
}

class _VisualChoicePageState extends State<VisualChoicePage> {
  /// null enquanto nada foi escolhido; true = Saúde da Mulher.
  bool? _rose;

  bool get _professional => AuthService.instance.entryChoice == 'professional';

  void _pick(bool rose) {
    setState(() => _rose = rose);
    AppPalette.apply(rose);
  }

  void _continue() {
    final rose = _rose;
    if (rose == null) return;
    EntryVisual.chosenRose = rose;
    Get.offAllNamed(EmailInputPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final pro = _professional;
    final kicker = pro ? 'Visual do seu painel' : 'Último passo';
    final title = pro
        ? 'Qual visual você quer no app?'
        : 'Como você quer usar a Pablife?';
    final lead = pro
        ? 'Muda só a figura e as cores. Agenda, pacientes e atendimentos '
              'continuam iguais.'
        : 'O app já abre do seu jeito, sem precisar procurar depois.';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: OnboardingBackground(scene: entryScene)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 14, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const OnboardingBrand(),
                      TextButton(
                        onPressed: () => Get.back<void>(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: OnboardingColors.text,
                        ),
                        child: const Text(
                          'Voltar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final art = _Art(rose: _rose == true);
                      final form = _Form(
                        kicker: kicker,
                        title: title,
                        lead: lead,
                        professional: pro,
                        rose: _rose,
                        onPick: _pick,
                        onContinue: _rose == null ? null : _continue,
                        wide: wide,
                      );
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 48 : 20,
                          wide ? 16 : 0,
                          wide ? 48 : 20,
                          32,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48,
                          ),
                          child: Center(
                            child: wide
                                ? ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1100,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 520,
                                            ),
                                            child: art,
                                          ),
                                        ),
                                        const SizedBox(width: 56),
                                        Expanded(child: form),
                                      ],
                                    ),
                                  )
                                : ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 480,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(width: 210, child: art),
                                        const SizedBox(height: 8),
                                        form,
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// As duas figuras, uma sobre a outra; a escolhida aparece.
class _Art extends StatelessWidget {
  final bool rose;

  const _Art({required this.rose});

  @override
  Widget build(BuildContext context) {
    Widget layer(String asset, String description, bool visible) =>
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: visible ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            scale: visible ? 1 : .94,
            child: Semantics(
              image: true,
              label: visible ? description : null,
              excludeSemantics: !visible,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
        );

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          layer(
            'assets/pages/auth/login_art.png',
            'Ilustração: busto lilás com coroa, jarro de carinhas e vaso '
                'com flor',
            !rose,
          ),
          layer(
            'assets/pages/auth/login_art_rose.png',
            'Ilustração: busto rosa com coroa amarela, jarro de carinhas e '
                'sol sobre nuvem',
            rose,
          ),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final String kicker;
  final String title;
  final String lead;
  final bool professional;
  final bool? rose;
  final ValueChanged<bool> onPick;
  final VoidCallback? onContinue;
  final bool wide;

  const _Form({
    required this.kicker,
    required this.title,
    required this.lead,
    required this.professional,
    required this.rose,
    required this.onPick,
    required this.onContinue,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = wide ? TextAlign.start : TextAlign.center;

    return Column(
      crossAxisAlignment: align,
      children: [
        AuthEntrance(
          delay: 120,
          child: Text(
            kicker.toUpperCase(),
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: OnboardingColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AuthEntrance(
          delay: 180,
          child: Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: wide ? 40 : 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
              color: OnboardingColors.text,
            ),
          ),
        ),
        SizedBox(height: wide ? 16 : 10),
        AuthEntrance(
          delay: 240,
          child: Text(
            lead,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: wide ? 17 : 15,
              height: 1.45,
              color: OnboardingColors.body,
            ),
          ),
        ),
        const SizedBox(height: 22),
        AuthEntrance(
          delay: 300,
          child: _Option(
            title: 'Pablife',
            subtitle: professional
                ? 'Figura verde, o visual clássico'
                : 'Bem-estar, metas e consultas',
            swatch: const [Color(0xFF052F33), Color(0xFF13B8B2)],
            selected: rose == false,
            onTap: () => onPick(false),
          ),
        ),
        const SizedBox(height: 12),
        AuthEntrance(
          delay: 360,
          child: _Option(
            title: 'Pablife Saúde da Mulher',
            subtitle: professional
                ? 'Figura rosa, em tons de rosa e lilás'
                : 'Ciclo, gestação e menopausa',
            swatch: const [Color(0xFF3A1D4F), Color(0xFFD63A74)],
            selected: rose == true,
            onTap: () => onPick(true),
          ),
        ),
        const SizedBox(height: 22),
        AuthEntrance(
          delay: 420,
          child: Align(
            alignment: wide ? Alignment.centerLeft : Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 320 : 480),
              child: _ContinueButton(onTap: onContinue),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Dá para trocar depois no Perfil.',
          textAlign: textAlign,
          style: const TextStyle(fontSize: 14, color: OnboardingColors.muted),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> swatch;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.title,
    required this.subtitle,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 2,
                color: selected
                    ? OnboardingColors.text
                    : Colors.white.withValues(alpha: .9),
              ),
            ),
            child: Row(
              children: [
                // Amostra das duas cores principais do visual.
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      Positioned(left: 0, top: 0, child: _dot(swatch[0], 30)),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _dot(swatch[1], 26),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: OnboardingColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: OnboardingColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? OnboardingColors.text
                        : Colors.transparent,
                    border: Border.all(
                      width: 2,
                      color: selected
                          ? OnboardingColors.text
                          : OnboardingColors.muted.withValues(alpha: .5),
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check,
                          size: 15,
                          color: Color(0xFFFBFAFC),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFFFBFAFC);
    return Opacity(
      opacity: onTap == null ? .4 : 1,
      child: Material(
        color: OnboardingColors.text,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  onTap == null ? 'Escolha uma opção' : 'Continuar',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
