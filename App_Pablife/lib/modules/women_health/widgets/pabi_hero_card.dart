import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/pabi/pabi.dart';
import '../pages/mood_check_in_page.dart';
import '../women_health_controller.dart';

/// Humores do cartão, com a carinha e a mensagem da PABI (canvas "PABI ·
/// Dashboard" e "PABI · Expressões e mensagens").
const pabiHeroMoods = <(String, PabiMood, String)>[
  ('Feliz', PabiMood.feliz, 'Que alegria! Guarde esse momento, ele é seu.'),
  ('Bem', PabiMood.bem, 'Que bom! Aproveite esse dia leve.'),
  ('Cansada', PabiMood.cansada, 'Descanse um pouquinho, você merece.'),
  (
    'Enjoada',
    PabiMood.enjoada,
    'Goles de água e refeições leves podem ajudar. Se continuar, fale com '
        'seu médico.',
  ),
  (
    'Ansiosa',
    PabiMood.ansiosa,
    'Respire fundo, uma coisa de cada vez. Quer conversar com um psicólogo?',
  ),
  (
    'Emotiva',
    PabiMood.emotiva,
    'Sentir muito também faz parte. Estou aqui com você.',
  ),
  (
    'Sensível',
    PabiMood.sensivel,
    'Você sente fundo, e tudo bem. Vá com calma e cuide de você.',
  ),
  (
    'Triste',
    PabiMood.triste,
    'Sinto muito. Você não precisa passar por isso sozinha. Que tal falar '
        'com um psicólogo da Pablife?',
  ),
];

/// A PABI no topo do Dashboard (Saúde da Mulher): grande, no centro do
/// cartão, sempre em movimento. Tocar nela abre a escolha das expressões;
/// depois de escolher, o cartão mostra "Hoje estou" e o humor em destaque.
class PabiHeroCard extends StatefulWidget {
  final WomenHealthController women;
  final String firstName;

  const PabiHeroCard({super.key, required this.women, this.firstName = ''});

  @override
  State<PabiHeroCard> createState() => _PabiHeroCardState();
}

class _PabiHeroCardState extends State<PabiHeroCard>
    with TickerProviderStateMixin {
  /// Flutuar, respirar e balançar.
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Nuvens passando devagar ao fundo.
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  /// Pulinho ao tocar ou ao registrar.
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "reduzir movimento" do aparelho.
    if (MediaQuery.of(context).disableAnimations) {
      _float.stop();
      _drift.stop();
    } else {
      if (!_float.isAnimating) _float.repeat(reverse: true);
      if (!_drift.isAnimating) _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _drift.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _hop() {
    if (MediaQuery.of(context).disableAnimations) return;
    _bounce.forward(from: 0);
  }

  /// Abre as expressões; a escolhida vira o humor de hoje.
  Future<void> _choose() async {
    _hop();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoodSheet(selected: widget.women.todayCheckIn),
    );
    if (picked == null || !mounted) return;
    if (picked == _details) {
      await MoodCheckInPage.open();
      return;
    }
    if (picked != widget.women.todayCheckIn) {
      await widget.women.toggleCheckIn(picked);
    }
    if (mounted) _hop();
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.women.todayCheckIn;
    final current = pabiHeroMoods.where((m) => m.$1 == today).firstOrNull;
    // Registro antigo (Tranquila, Irritada...): usa a carinha mais próxima.
    final face = today == null ? PabiMood.bem : PabiMood.fromCheckIn(today);
    final name = widget.firstName.isEmpty ? '' : ', ${widget.firstName}';

    return Semantics(
      button: true,
      label: today == null
          ? 'PABI pergunta como você está hoje. Toque para escolher'
          : 'Hoje estou ${today.toLowerCase()}. Toque para trocar',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFFFF1F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFF3CFE3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _choose,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            child: Column(
              children: [
                SizedBox(
                  height: 230,
                  child: _Stage(
                    float: _float,
                    drift: _drift,
                    bounce: _bounce,
                    mood: face,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(today),
                    children: [
                      Text(
                        today == null ? 'Oi$name!' : 'Hoje estou',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PabColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          today == null
                              ? 'Como você está hoje?'
                              : today.toLowerCase(),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: today == null ? 26 : 38,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        today == null
                            ? 'Toque em mim para escolher.'
                            : current?.$3 ??
                                  'Obrigada por me contar como você está.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Parece botão, mas o cartão inteiro responde ao toque.
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: PabColors.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        today == null
                            ? 'Escolher como estou'
                            : 'Trocar como estou',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PabColors.onInk,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 18,
                        color: PabColors.onInk,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Valor devolvido pela folha quando a usuária quer o registro completo.
const _details = '__detalhes__';

/// O palco: nuvens passando, o chão e a PABI grande flutuando.
class _Stage extends StatelessWidget {
  final Animation<double> float;
  final Animation<double> drift;
  final Animation<double> bounce;
  final PabiMood mood;

  const _Stage({
    required this.float,
    required this.drift,
    required this.bounce,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    const size = 150.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([float, drift, bounce]),
          builder: (context, child) {
            final t = Curves.easeInOut.transform(float.value);
            final d = Curves.easeInOut.transform(drift.value);
            final b = bounce.value == 0
                ? 1.0
                : Curves.elasticOut.transform(bounce.value);
            final hop = bounce.value == 0
                ? 0.0
                : -26 * (1 - (2 * bounce.value - 1).abs()).clamp(0.0, 1.0);
            final dy = -7 + 14 * t + hop;
            final scale = (1 + 0.035 * t) * (0.9 + 0.1 * b);
            // Balanço leve de um lado para o outro.
            final tilt = math.sin(float.value * math.pi) * 0.05 - 0.025;
            final lift = ((dy + 33) / 47).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: width * 0.02 + 14 * d,
                  top: 46,
                  child: const _Cloud(width: 96),
                ),
                Positioned(
                  right: width * 0.04 + 18 * (1 - d),
                  top: 26,
                  child: const _Cloud(width: 68),
                ),
                Positioned(
                  right: width * 0.1 - 10 * d,
                  top: 104,
                  child: const _Cloud(width: 84),
                ),
                // Chão.
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: math.min(width * 0.72, 260),
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7D9EA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                // Sombra: encolhe quando ela sobe.
                Positioned(
                  bottom: 18,
                  child: Container(
                    width: 92 * (0.6 + 0.4 * lift),
                    height: 10,
                    decoration: BoxDecoration(
                      color: PabColors.ink.withValues(
                        alpha: 0.07 + 0.09 * lift,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: tilt,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                ),
              ],
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PabColors.pink.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Pabi(
                key: ValueKey(mood),
                mood: mood,
                women: true,
                size: size,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Nuvem branca do fundo.
class _Cloud extends StatelessWidget {
  final double width;

  const _Cloud({required this.width});

  @override
  Widget build(BuildContext context) {
    final h = width * 0.34;
    return SizedBox(
      width: width,
      height: h * 1.7,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(h),
              ),
            ),
          ),
          Positioned(
            left: width * 0.22,
            bottom: h * 0.35,
            child: Container(
              width: width * 0.42,
              height: width * 0.42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folha "Como estou hoje?": as 8 expressões para escolher.
class _MoodSheet extends StatelessWidget {
  final String? selected;

  const _MoodSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: PabColors.card,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PabColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Como estou hoje?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toque na expressão que mais combina com você agora.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: PabColors.muted),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final width = (constraints.maxWidth - 3 * gap) / 4;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final (label, mood, _) in pabiHeroMoods)
                        SizedBox(
                          width: width,
                          child: _MoodChoice(
                            label: label,
                            mood: mood,
                            selected: label == selected,
                            onTap: () => Navigator.of(context).pop(label),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_details),
                style: TextButton.styleFrom(
                  foregroundColor: PabColors.softText,
                  minimumSize: const Size(0, 44),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contar mais e ver conselhos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18),
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

/// Uma expressão na folha de escolha.
class _MoodChoice extends StatelessWidget {
  final String label;
  final PabiMood mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChoice({
    required this.label,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Estou ${label.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: selected ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? PabColors.pink : PabColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
            child: Column(
              children: [
                Pabi(mood: mood, women: true, size: 56),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: PabColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
