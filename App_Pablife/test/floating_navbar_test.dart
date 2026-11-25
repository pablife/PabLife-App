import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/modules/dashboard/widgets/dashboard_navbar.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double safeBottom = 0,
    bool professional = false,
    int current = 0,
    ValueChanged<int>? onTab,
    ScrollController? scroll,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: safeBottom);
    tester.view.viewPadding = FakeViewPadding(bottom: safeBottom);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FloatingNavScaffold(
          navbar: DashboardNavbar(
            currentIndex: current,
            onTab: onTab ?? (_) {},
            isProfessional: professional,
          ),
          // Igual às abas: um Scaffold dentro do outro.
          body: Scaffold(
            body: Builder(
              builder: (context) => ListView(
                controller: scroll,
                padding: EdgeInsets.only(
                  bottom: 24 + FloatingNavSpace.of(context),
                ),
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 60, child: Text('item $i')),
                ],
              ),
            ),
            floatingActionButton: Builder(
              builder: (context) => Padding(
                padding: EdgeInsets.only(bottom: FloatingNavSpace.of(context)),
                child: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect bar(WidgetTester tester) => tester.getRect(
    find
        .descendant(
          of: find.byType(DashboardNavbar),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );

  for (final safe in [0.0, 34.0, 48.0]) {
    testWidgets('solta das bordas e acima da faixa do sistema ($safe)', (
      tester,
    ) async {
      final scroll = ScrollController();
      await pump(tester, safeBottom: safe, scroll: scroll);
      final rect = bar(tester);
      expect(rect.left, 16);
      expect(rect.right, 390 - 16);
      expect(844 - rect.bottom, greaterThan(safe));

      // O conteúdo vai até o fim da tela, por trás da barra.
      expect(tester.getRect(find.byType(ListView)).bottom, 844);
      // No fim da rolagem, o último item fica acima dela.
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(
        tester.getRect(find.text('item 39')).bottom,
        lessThanOrEqualTo(rect.top),
      );
      // O botão "+" também.
      expect(
        tester.getRect(find.byType(FloatingActionButton)).bottom,
        lessThanOrEqualTo(rect.top),
      );
    });
  }

  testWidgets('sem nomes na tela, mas com nome para leitor de tela', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final tab in dashboardTabs(isProfessional: false)) {
      expect(find.text(tab.label), findsNothing);
      expect(find.bySemanticsLabel(tab.label), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('cada ícone abre a sua aba, nos dois perfis', (tester) async {
    for (final professional in [false, true]) {
      final opened = <int>[];
      await pump(tester, professional: professional, onTab: opened.add);
      final tabs = dashboardTabs(isProfessional: professional);
      for (final tab in tabs) {
        await tester.tap(find.byIcon(tab.icon));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(opened, [for (final tab in tabs) tab.index]);
    }
  });

  testWidgets('cabe em celular estreito e não estica em tablet', (
    tester,
  ) async {
    await pump(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await pump(tester, size: const Size(820, 1180));
    expect(bar(tester).width, 480);
    expect(bar(tester).center.dx, 410);
  });
}
