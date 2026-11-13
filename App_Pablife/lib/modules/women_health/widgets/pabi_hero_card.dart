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

/// A PABI no topo do Dashboard (Saúde da Mulher): flutua, reage ao toque e
/// pergunta como a usuária está. Tocar numa carinha registra o humor do dia
/// e a PABI muda de expressão.
class PabiHeroCard extends StatefulWidget {
  final WomenHealthController women;
  final String firstName;

  const PabiHeroCard({super.key, required this.women, this.firstName = ''});

  @override
  State<PabiHeroCard> createState() => _PabiHeroCardState();
}

class _PabiHeroCardState extends State<PabiHeroCard>
    with TickerProviderStateMixin {
  /// Flutuar e "respirar".
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Pulinho ao tocar ou ao registrar.
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "reduzir movimento" do aparelho.
    if (MediaQuery.of(context).disableAnimations) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _hop() {
    if (MediaQuery.of(context).disableAnimations) return;
    _bounce.forward(from: 0);
  }

  Future<void> _pick(String label) async {
    if (_saving) return;
    _hop();
    if (widget.women.todayCheckIn == label) return;
    setState(() => _saving = true);
    await widget.women.toggleCheckIn(label);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.women.todayCheckIn;
    final current = pabiHeroMoods.where((m) => m.$1 == today).firstOrNull;
    // Registro antigo (Tranquila, Irritada...): usa a carinha mais próxima.
    final face = today == null ? PabiMood.bem : PabiMood.fromCheckIn(today);
    final name = widget.firstName.isEmpty ? '' : ', ${widget.firstName}';

    final title = today == null
        ? 'Oi$name! Como você está hoje?'
        : 'Hoje estou ${today.toLowerCase()}';
    final message = today == null
        ? 'Toque numa carinha para me contar.'
        : current?.$3 ?? 'Obrigada por me contar como você está.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF1F8)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3CFE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnimatedPabi(
                float: _float,
                bounce: _bounce,
                mood: face,
                onTap: _hop,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Column(
                    key: ValueKey(today),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            today == null
                ? 'Como você está agora?'
                : 'Mudou? Toque para trocar',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // 4 por linha no celular; todas numa linha quando cabe.
              final columns = constraints.maxWidth >= 560 ? 8 : 4;
              final width = constraints.maxWidth / columns;
              return Wrap(
                runSpacing: 6,
                children: [
                  for (final (label, mood, _) in pabiHeroMoods)
                    SizedBox(
                      width: width,
                      child: _MoodChoice(
                        label: label,
                        mood: mood,
                        selected: label == today,
                        onTap: () => _pick(label),
                      ),
                    ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: MoodCheckInPage.open,
              style: TextButton.styleFrom(
                foregroundColor: PabColors.softText,
                minimumSize: const Size(0, 44),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    today == null
                        ? 'Registrar com detalhes'
                        : 'Contar mais e ver conselhos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A PABI grande: flutua, respira, dá um pulinho ao toque e troca de
/// expressão com um "pop".
class _AnimatedPabi extends StatelessWidget {
  final Animation<double> float;
  final Animation<double> bounce;
  final PabiMood mood;
  final VoidCallback onTap;

  const _AnimatedPabi({
    required this.float,
    required this.bounce,
    required this.mood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    return Semantics(
      button: true,
      label: 'PABI ${mood.label}. Toque para brincar',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size + 8,
          height: size + 22,
          child: AnimatedBuilder(
            animation: Listenable.merge([float, bounce]),
            builder: (context, child) {
              final t = Curves.easeInOut.transform(float.value);
              // Pulinho: sobe e volta, com um balanço no fim.
              final b = bounce.isAnimating || bounce.value > 0
                  ? Curves.elasticOut.transform(bounce.value)
                  : 1.0;
              final hop = bounce.value == 0
                  ? 0.0
                  : -18 * (1 - (2 * bounce.value - 1).abs()).clamp(0.0, 1.0);
              final dy = -4 + 8 * t + hop;
              final scale = (1 + 0.03 * t) * (0.9 + 0.1 * b);
              final lift = ((dy + 22) / 30).clamp(0.0, 1.0);
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Sombra no chão: encolhe quando ela sobe.
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 56 * (0.6 + 0.4 * lift),
                      height: 8,
                      decoration: BoxDecoration(
                        color: PabColors.pink.withValues(
                          alpha: 0.12 + 0.16 * lift,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(scale: scale, child: child),
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
                    color: PabColors.pink.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
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
          ),
        ),
      ),
    );
  }
}

/// Carinha pequena para escolher o humor.
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
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? PabColors.pink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Pabi(mood: mood, women: true, size: 48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: PabColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
