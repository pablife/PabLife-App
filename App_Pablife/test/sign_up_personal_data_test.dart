import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/models/gender.dart';
import 'package:pablife/modules/auth/pages/widgets/personal_data_fields.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('a data ganha as barras enquanto a pessoa digita', (
    tester,
  ) async {
    var typed = '';
    await pump(tester, BirthDateField(onChanged: (v) => typed = v));
    await tester.enterText(find.byType(TextFormField), '05081990');
    expect(typed, '05/08/1990');
  });

  testWidgets('gênero: marca e, tocando de novo, desmarca', (tester) async {
    Gender? value;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => GenderField(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.text('Feminino'));
    await tester.pump();
    expect(value, Gender.female);
    await tester.tap(find.text('Feminino'));
    await tester.pump();
    expect(value, isNull);
  });

  testWidgets('cabe em celular estreito com letra grande', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: GenderField(value: null, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
