import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/shared/themes/app_palette.dart';

void main() {
  tearDown(() => AppPalette.isRose = false);

  testWidgets('fundo de caixa muda ao trocar a paleta com a tela aberta', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColor(0xFF00343D)),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    final box = tester.renderObject<RenderDecoratedBox>(
      find.byType(DecoratedBox),
    );
    expect(box, paints..rect(color: const Color(0xFF00343D)));

    AppPalette.isRose = true;
    AppPalette.resetCachedDecorations();
    box.markNeedsPaint();
    await tester.pump();

    expect(box, paints..rect(color: const Color(0xFF4A3560)));
  });
}
