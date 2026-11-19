import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pablife/widgets/photo_crop/photo_crop_page.dart';

void main() {
  testWidgets('recorta uma foto retangular em um quadrado', (tester) async {
    // Foto em pé (400 x 800): metade de cima vermelha, metade de baixo azul.
    final photo = img.Image(width: 400, height: 800);
    img.fill(photo, color: img.ColorRgb8(0, 0, 255));
    img.fillRect(
      photo,
      x1: 0,
      y1: 0,
      x2: 399,
      y2: 399,
      color: img.ColorRgb8(255, 0, 0),
    );
    final bytes = Uint8List.fromList(img.encodePng(photo));

    Uint8List? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Uint8List>(
                MaterialPageRoute(builder: (_) => PhotoCropPage(bytes: bytes)),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Usar esta foto'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Usar esta foto'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    final cropped = img.decodeImage(result!)!;
    expect(cropped.width, cropped.height);
    // Começa centralizada: o centro da foto (divisa vermelho/azul) fica no
    // meio do recorte; o topo do recorte é vermelho, a base é azul.
    final top = cropped.getPixel(cropped.width ~/ 2, 5);
    final bottom = cropped.getPixel(cropped.width ~/ 2, cropped.height - 5);
    expect(top.r, greaterThan(200));
    expect(bottom.b, greaterThan(200));
  });
}
