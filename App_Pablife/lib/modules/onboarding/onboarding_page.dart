import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/pages/widgets/auth_animated_background.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_background.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<OnboardingController>(
        builder: (controller) {
          final index = controller.currentPage;
          final slide = controller.slides[index];

          return Stack(
            children: [
              Positioned.fill(child: OnboardingBackground(scene: slide.scene)),
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
                          _Header(onSkip: controller.skipOnboarding),
                          // A troca de tela refaz as animações de entrada.
                          _Slide(
                            key: ValueKey(index),
                            slide: slide,
                            index: index,
                            total: controller.slides.length,
                            maxWidth: constraints.maxWidth,
                            onNext: controller.nextPage,
                            onBack: index == 0 ? null : controller.previousPage,
                          ),
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
}

class _Header extends StatelessWidget {
  final VoidCallback onSkip;

  const _Header({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const OnboardingBrand(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: OnboardingColors.text),
            child: const Text(
              'Pular',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca "pablife." das telas claras.
class OnboardingBrand extends StatelessWidget {
  const OnboardingBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        text: 'pablife',
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: OnboardingColors.accent),
          ),
        ],
      ),
      semanticsLabel: 'PabLife',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
        color: OnboardingColors.text,
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final OnboardingSlide slide;
  final int index;
  final int total;
  final double maxWidth;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _Slide({
    super.key,
    required this.slide,
    required this.index,
    required this.total,
    required this.maxWidth,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final wide = maxWidth >= 820;
    final art = AuthEntrance(
      from: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: .5,
                  colors: [
                    Colors.white.withValues(alpha: .75),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          AuthFloatingArt(
            asset: slide.imagePath,
            description: slide.imageDescription,
            aspectRatio: 810 / 741,
            fadeEdges: true,
          ),
        ],
      ),
    );
    final text = _SlideText(
      slide: slide,
      index: index,
      total: total,
      onNext: onNext,
      onBack: onBack,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 64 : 20, 8, wide ? 64 : 20, 40),
        child: wide
            ? Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: art,
                    ),
                  ),
                  const SizedBox(width: 72),
                  Expanded(child: text),
                ],
              )
            : Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: art,
                  ),
                  const SizedBox(height: 16),
                  text,
                ],
              ),
      ),
    );
  }
}

class _SlideText extends StatelessWidget {
  final OnboardingSlide slide;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _SlideText({
    required this.slide,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthEntrance(
            child: _Progress(index: index, total: total),
          ),
          const SizedBox(height: 20),
          AuthEntrance(
            delay: 120,
            child: Text(
              slide.title,
              style: const TextStyle(
                fontSize: 40,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: -.9,
                color: OnboardingColors.text,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthEntrance(
            delay: 240,
            child: Text(
              slide.description,
              style: const TextStyle(
                fontSize: 18,
                height: 1.55,
                color: OnboardingColors.body,
              ),
            ),
          ),
          const SizedBox(height: 28),
          AuthEntrance(
            delay: 360,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OnboardingButton(label: slide.buttonLabel, onTap: onNext),
                if (onBack != null)
                  TextButton(
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: OnboardingColors.text,
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

class _Progress extends StatelessWidget {
  final int index;
  final int total;

  const _Progress({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASSO ${index + 1} DE $total',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: OnboardingColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _ProgressBar(state: i - index)),
            ],
          ],
        ),
      ],
    );
  }
}

/// [state] negativo: passo feito; zero: passo atual, que enche ao abrir.
class _ProgressBar extends StatelessWidget {
  final int state;

  const _ProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: OnboardingColors.text.withValues(alpha: .14)),
            if (state < 0)
              const ColoredBox(color: OnboardingColors.text)
            else if (state == 0)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                ),
                child: const ColoredBox(color: OnboardingColors.text),
              ),
          ],
        ),
      ),
    );
  }
}

/// Botão escuro arredondado, com seta, das telas de entrada.
class OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool expand;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.expand = false,
  });

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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: expand ? double.infinity : 220,
              minHeight: 56,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: foreground,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
