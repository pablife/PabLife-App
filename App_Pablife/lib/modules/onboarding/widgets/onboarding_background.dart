import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../shared/themes/app_palette.dart';

abstract final class OnboardingColors {
  static const text = AppColor.pair(0xFF052F33, 0xFF3A1D4F);
  static const body = AppColor.pair(0xFF2A4649, 0xFF5E4A66);
  static const muted = AppColor.pair(0xFF35575B, 0xFF7A5A86);
  static const accent = AppColor.pair(0xFF0E7F7B, 0xFFD63A74);
  static const pink = AppColor.pair(0xFFFF8ECF, 0xFFEEC3D8);
  static const yellow = AppColor.pair(0xFFF5E94C, 0xFFFFC2E6);
  static const lilac = AppColor.pair(0xFFA497F7, 0xFFD9B8F5);
  static const lime = AppColor.pair(0xFFC6F45A, 0xFFD6A6DB);
  static const sky = AppColor.pair(0xFF8FD3F4, 0xFFFF8ECF);
}

/// Mancha colorida. Posição: use [left] ou [right], e [top] ou [bottom].
/// Valores até 1 (e maiores que -1) são proporção da tela; o resto, pixels.
class BackgroundBlob {
  final double? left, right, top, bottom;
  final double width, height;
  final Color color;
  final double opacity;
  final double delay;
  final double period;

  const BackgroundBlob({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
    this.delay = 0,
    this.period = 14,
  });
}

class BackgroundBubble {
  final double left;
  final double bottom;
  final double size;
  final Color color;
  final double delay;
  final double period;

  const BackgroundBubble(
    this.left,
    this.bottom,
    this.size,
    this.color, {
    this.delay = 0,
    this.period = 9,
  });
}

/// Cenário de cada tela da apresentação.
class OnboardingScene {
  final List<Color> gradient;
  final List<BackgroundBlob> blobs;
  final List<BackgroundBubble> bubbles;
  final double waveTop;
  final double cloudLeft;
  final double cloudTop;
  final double cloudWidth;

  const OnboardingScene({
    required this.gradient,
    required this.blobs,
    required this.bubbles,
    required this.waveTop,
    required this.cloudLeft,
    required this.cloudTop,
    required this.cloudWidth,
  });
}

/// Fundo claro da apresentação: manchas que mudam de forma, ondas, nuvem e
/// bolhas. Com "reduzir movimento" ligado no aparelho, fica parado.
class OnboardingBackground extends StatefulWidget {
  final OnboardingScene scene;

  const OnboardingBackground({super.key, required this.scene});

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    // O movimento é lento: 24 quadros por segundo bastam e pesam bem menos.
    _ticker = createTicker((elapsed) {
      final now = elapsed.inMilliseconds / 1000;
      if (now - _seconds.value >= 1 / 24) _seconds.value = now;
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
          painter: _ScenePainter(widget.scene, _seconds),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final OnboardingScene scene;
  final ValueNotifier<double> seconds;

  Size? _gradientSize;
  Paint? _gradient;

  _ScenePainter(this.scene, this.seconds) : super(repaint: seconds);

  /// Formas (cantos em %) por onde cada mancha passa.
  static const _shapes = <List<double>>[
    [58, 42, 63, 37, 45, 55, 45, 55],
    [40, 60, 38, 62, 60, 35, 65, 40],
    [65, 35, 50, 50, 38, 62, 38, 62],
  ];
  static const _moves = <List<double>>[
    [0, 0, 1],
    [14, -18, 1.06],
    [-10, 10, .96],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    if (size != _gradientSize) {
      _gradientSize = size;
      _gradient = Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-.5, -1),
          end: const Alignment(.5, 1),
          colors: scene.gradient,
        ).createShader(Offset.zero & size);
    }
    canvas.drawRect(Offset.zero & size, _gradient!);

    for (final blob in scene.blobs) {
      _blob(canvas, size, blob, t);
    }
    _waves(canvas, size, t);
    _cloud(canvas, size, t);
    for (final bubble in scene.bubbles) {
      _bubble(canvas, size, bubble, t);
    }
  }

  double _resolve(double value, double total) =>
      value.abs() <= 1 ? value * total : value;

  void _blob(Canvas canvas, Size size, BackgroundBlob blob, double t) {
    final x = blob.left != null
        ? _resolve(blob.left!, size.width)
        : size.width - _resolve(blob.right!, size.width) - blob.width;
    final y = blob.top != null
        ? _resolve(blob.top!, size.height)
        : size.height - _resolve(blob.bottom!, size.height) - blob.height;

    final phase = ((t + blob.delay) / blob.period) % 1 * 3;
    final from = phase.floor() % 3;
    final to = (from + 1) % 3;
    final k = Curves.easeInOut.transform(phase - phase.floor());
    double mix(List<List<double>> table, int i) =>
        table[from][i] + (table[to][i] - table[from][i]) * k;

    final scale = mix(_moves, 2);
    final w = blob.width * scale;
    final h = blob.height * scale;
    final rect = Rect.fromLTWH(x + mix(_moves, 0), y + mix(_moves, 1), w, h);
    Radius corner(int a, int b) =>
        Radius.elliptical(w * mix(_shapes, a) / 100, h * mix(_shapes, b) / 100);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: corner(0, 4),
        topRight: corner(1, 5),
        bottomRight: corner(2, 6),
        bottomLeft: corner(3, 7),
      ),
      Paint()..color = blob.color.withValues(alpha: blob.opacity),
    );
  }

  void _waves(Canvas canvas, Size size, double t) {
    const period = 28.0;
    final shift = -(t % period) / period * size.width;
    final top = size.height * scene.waveTop;

    Path line(double y, double amplitude) {
      final path = Path()..moveTo(shift, top + y);
      final step = size.width / 2;
      for (var i = 0; i < 8; i++) {
        final x = shift + step * i;
        path.quadraticBezierTo(
          x + step / 2,
          top + y + (i.isEven ? -amplitude : amplitude),
          x + step,
          top + y,
        );
      }
      return path;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: .7);
    canvas.drawPath(line(85, 68), paint..strokeWidth = 3);
    paint.color = Colors.white.withValues(alpha: .49);
    canvas.drawPath(line(119, 60), paint..strokeWidth = 1.5);
  }

  void _cloud(Canvas canvas, Size size, double t) {
    final k = (1 - math.cos(2 * math.pi * t / 18)) / 2;
    final scale = scene.cloudWidth / 120;
    final dx = size.width * scene.cloudLeft + 48 * k;
    final dy = size.height * scene.cloudTop;
    final paint = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    // Camada única: as partes da nuvem não escurecem onde se sobrepõem.
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 120, 70),
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
    canvas.drawCircle(const Offset(28, 40), 22, paint);
    canvas.drawCircle(const Offset(56, 30), 30, paint);
    canvas.drawCircle(const Offset(90, 42), 20, paint);
    canvas.drawRect(const Rect.fromLTWH(28, 40, 62, 22), paint);
    canvas.restore();
    canvas.restore();
  }

  void _bubble(Canvas canvas, Size size, BackgroundBubble bubble, double t) {
    final k = ((t + bubble.delay) / bubble.period) % 1;
    final rise = Curves.easeIn.transform(k) * 260;
    final opacity = k < .15 ? k / .15 * .85 : .85 * (1 - (k - .15) / .85);
    canvas.drawCircle(
      Offset(
        size.width * bubble.left,
        size.height - bubble.bottom - bubble.size / 2 - rise,
      ),
      bubble.size / 2,
      Paint()..color = bubble.color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => oldDelegate.scene != scene;
}
