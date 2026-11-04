import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../shared/themes/app_palette.dart';

/// Cores das telas de login.
abstract final class AuthColors {
  static const background = AppColor(0xFF00343D);
  static const panel = AppColor.pair(0xFFC4CCFD, 0xFFF4EEE9);
  static const text = AppColor.pair(0xFF052F33, 0xFF4A3560);
  static const muted = AppColor.pair(0xFF33505A, 0xFF6B5A7B);
  static const accent = AppColor.pair(0xFF13B8B2, 0xFF8F72E0);
  static const brandPink = AppColor.pair(0xFFF7C3DF, 0xFFEEC3D8);
  static const lilac = AppColor.pair(0xFFB9B3FF, 0xFFD6A6DB);
  static const pink = AppColor.pair(0xFFFF8ECF, 0xFFEEC3D8);
  static const yellow = AppColor.pair(0xFFF5E94C, 0xFFF4EEE9);
  static const error = Color(0xFF9B1B4E);
  static const errorBorder = Color(0xFFC2185B);
  static const hint = Color(0xFF6B7F82);
}

/// Fundo das telas de login: manchas de luz, ondas e estrelas animadas.
/// Com "reduzir movimento" ligado no aparelho, fica parado.
class AuthAnimatedBackground extends StatefulWidget {
  const AuthAnimatedBackground({super.key});

  @override
  State<AuthAnimatedBackground> createState() => _AuthAnimatedBackgroundState();
}

class _AuthAnimatedBackgroundState extends State<AuthAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMilliseconds / 1000;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BackgroundPainter(_seconds),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final ValueNotifier<double> seconds;

  _BackgroundPainter(this.seconds) : super(repaint: seconds);

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    canvas.drawRect(Offset.zero & size, Paint()..color = AuthColors.background);

    _orb(
      canvas,
      Offset(60, size.height * .1 + 180),
      180,
      AuthColors.accent,
      .35,
      t,
      16,
    );
    _orb(
      canvas,
      Offset(size.width - 60, size.height * .3 + 200),
      200,
      AuthColors.lilac,
      .25,
      t + 6,
      20,
    );
    _orb(
      canvas,
      Offset(size.width * .3 + 210, size.height),
      190,
      AuthColors.pink,
      .2,
      t + 10,
      22,
    );

    _waves(canvas, size, t);

    _star(
      canvas,
      Offset(size.width * .12, size.height * .14),
      8,
      AuthColors.yellow,
      t,
    );
    _star(
      canvas,
      Offset(size.width * .84, size.height * .09),
      6,
      Colors.white,
      t + 1.2,
    );
    _star(
      canvas,
      Offset(size.width * .91, size.height * .38),
      9,
      AuthColors.pink,
      t + 2.4,
    );
    _star(
      canvas,
      Offset(size.width * .07, size.height * .46),
      6,
      AuthColors.lilac,
      t + .6,
    );
  }

  /// Sobe e desce entre 0 e 1 a cada [period] segundos.
  double _wave(double t, double period) =>
      (1 - math.cos(2 * math.pi * t / period)) / 2;

  void _orb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
    double t,
    double period,
  ) {
    final k = _wave(t, period);
    final c = center + Offset(30 * k, -24 * k);
    final r = radius * (1 + .12 * k);
    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.5)),
    );
  }

  void _waves(Canvas canvas, Size size, double t) {
    const period = 30.0;
    final width = size.width * 2;
    final shift = -(t % period) / period * size.width;
    final top = size.height * .22;

    Path line(double y, double amplitude) {
      final path = Path()..moveTo(shift, top + y);
      final step = width / 4;
      for (var i = 0; i < 8; i++) {
        final x = shift + step * i;
        final direction = i.isEven ? -1 : 1;
        path.quadraticBezierTo(
          x + step / 2,
          top + y + amplitude * direction,
          x + step,
          top + y,
        );
      }
      return path;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: .14);
    canvas.drawPath(line(90, 80), paint..strokeWidth = 3);
    canvas.drawPath(line(126, 70), paint..strokeWidth = 1.5);
  }

  void _star(Canvas canvas, Offset c, double r, Color color, double t) {
    final k = _wave(t, 3.5);
    final size = r * (.6 + .4 * k);
    final inner = size * .2;
    final path = Path()
      ..moveTo(c.dx, c.dy - size)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(c.dx + size, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, c.dy + size)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(c.dx - size, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: .15 + .75 * k),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

/// Ilustração flutuando devagar, sem animar se o movimento estiver reduzido.
class AuthFloatingArt extends StatefulWidget {
  final String asset;
  final String description;

  /// Largura ÷ altura da imagem: reserva o espaço enquanto ela carrega.
  final double aspectRatio;

  const AuthFloatingArt({
    super.key,
    required this.asset,
    required this.description,
    required this.aspectRatio,
  });

  @override
  State<AuthFloatingArt> createState() => _AuthFloatingArtState();
}

class _AuthFloatingArtState extends State<AuthFloatingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -12 * Curves.easeInOut.transform(_float.value)),
        child: child,
      ),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Image.asset(
          widget.asset,
          fit: BoxFit.contain,
          semanticLabel: widget.description,
        ),
      ),
    );
  }
}

/// Entrada suave de um bloco: aparece subindo (ou descendo, com [from]
/// negativo) depois de [delay] milissegundos.
class AuthEntrance extends StatelessWidget {
  final Widget child;
  final double from;
  final int delay;

  const AuthEntrance({
    super.key,
    required this.child,
    this.from = 18,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay + 700;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, value, child) {
        final k = Curves.easeOutCubic.transform(
          ((value * total - delay) / 700).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: k,
          child: Transform.translate(
            offset: Offset(0, from * (1 - k)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
