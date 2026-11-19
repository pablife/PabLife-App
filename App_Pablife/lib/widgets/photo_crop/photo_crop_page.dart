import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/photo_resize.dart';

/// Tela para posicionar a foto de perfil dentro do círculo antes do envio.
///
/// A pessoa arrasta a foto e aproxima com os dedos (ou o controle deslizante,
/// no computador). Devolve a parte escolhida já recortada em quadrado, em
/// JPEG de [profilePhotoMaxSide] px — ou `null` se cancelar.
class PhotoCropPage extends StatefulWidget {
  const PhotoCropPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

/// Lado maior da foto usada na tela de recorte: basta para recortar com
/// qualidade e deixa a abertura rápida mesmo com fotos de câmera grandes.
const int _workingMaxSide = 1400;

class _PhotoCropPageState extends State<PhotoCropPage> {
  img.Image? _photo;
  Uint8List? _preview;
  bool _failed = false;
  bool _saving = false;

  final _transform = TransformationController();
  double _viewport = 0;
  double _baseScale = 1;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  bool _resetting = false;

  void _onTransform() {
    if (_resetting) return;
    final z = _transform.value.getMaxScaleOnAxis();
    if ((z - _zoom).abs() > 0.001) setState(() => _zoom = z);
  }

  Future<void> _load() async {
    final decoded = img.decodeImage(widget.bytes);
    if (decoded == null) {
      setState(() => _failed = true);
      return;
    }
    var photo = img.bakeOrientation(decoded);
    final longest = math.max(photo.width, photo.height);
    if (longest > _workingMaxSide) {
      photo = photo.width >= photo.height
          ? img.copyResize(photo, width: _workingMaxSide)
          : img.copyResize(photo, height: _workingMaxSide);
    }
    final preview = img.encodeJpg(photo, quality: 90);
    if (!mounted) return;
    setState(() {
      _photo = photo;
      _preview = preview;
    });
  }

  /// Começa com a foto cobrindo o círculo e centralizada.
  void _resetFor(double viewport) {
    final photo = _photo!;
    _viewport = viewport;
    _baseScale = viewport / math.min(photo.width, photo.height);
    final w = photo.width * _baseScale;
    final h = photo.height * _baseScale;
    // Chamado durante o build: muda a posição sem pedir novo setState.
    _resetting = true;
    _transform.value = Matrix4.identity()
      ..translateByDouble(-(w - viewport) / 2, -(h - viewport) / 2, 0, 1);
    _resetting = false;
    _zoom = 1;
  }

  void _setZoom(double zoom) {
    // Aproxima mantendo o centro do círculo no mesmo ponto da foto.
    final m = _transform.value;
    final current = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final center = _viewport / 2;
    final px = (center - t.x) / current;
    final py = (center - t.y) / current;
    final photo = _photo!;
    final w = photo.width * _baseScale * zoom;
    final h = photo.height * _baseScale * zoom;
    final tx = (center - px * zoom).clamp(_viewport - w, 0.0);
    final ty = (center - py * zoom).clamp(_viewport - h, 0.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  Future<void> _confirm() async {
    final photo = _photo;
    if (photo == null || _saving) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final m = _transform.value;
    final scale = m.getMaxScaleOnAxis() * _baseScale;
    final t = m.getTranslation();
    var side = (_viewport / scale).round();
    var x = (-t.x / scale).round();
    var y = (-t.y / scale).round();
    side = side.clamp(1, math.min(photo.width, photo.height));
    x = x.clamp(0, photo.width - side);
    y = y.clamp(0, photo.height - side);

    var square = img.copyCrop(photo, x: x, y: y, width: side, height: side);
    if (side > profilePhotoMaxSide) {
      square = img.copyResize(
        square,
        width: profilePhotoMaxSide,
        height: profilePhotoMaxSide,
        interpolation: img.Interpolation.average,
      );
    }
    final bytes = img.encodeJpg(square, quality: 85);
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101414),
        foregroundColor: Colors.white,
        title: const Text('Ajustar foto'),
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _failed
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível abrir esta imagem. Tente outra foto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
            : _photo == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _editor(),
      ),
    );
  }

  Widget _editor() {
    final photo = _photo!;
    return LayoutBuilder(
      builder: (context, box) {
        final viewport = math
            .min(box.maxWidth - 32, box.maxHeight - 200)
            .clamp(200.0, 420.0)
            .toDouble();
        if ((viewport - _viewport).abs() > 0.5) _resetFor(viewport);
        final w = photo.width * _baseScale;
        final h = photo.height * _baseScale;
        return Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Arraste e aproxime para ajustar a foto no círculo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SizedBox.square(
                  dimension: viewport,
                  child: Stack(
                    children: [
                      ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transform,
                          constrained: false,
                          minScale: 1,
                          maxScale: 5,
                          boundaryMargin: EdgeInsets.zero,
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Image.memory(
                              _preview!,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                      const IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _CircleMaskPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _zoom.clamp(1.0, 5.0),
                      min: 1,
                      max: 5,
                      activeColor: PabColors.accent,
                      label: 'Aproximação',
                      onChanged: _setZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white70),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: PabColors.accent,
                    foregroundColor: PabColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _saving ? null : _confirm,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Usar esta foto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Escurece o que fica fora do círculo e desenha a borda do círculo.
class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect.deflate(2));
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      circle,
    );
    canvas.drawPath(outside, Paint()..color = const Color(0x99000000));
    canvas.drawPath(
      circle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
