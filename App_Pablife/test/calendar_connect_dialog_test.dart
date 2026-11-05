import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/repositories/calendar_feed_repository.dart';
import 'package:pablife/modules/calendar/widgets/calendar_connect_dialog.dart';

class _FakeRepository extends CalendarFeedRepository {
  final Map<String, Map<String, dynamic>> feeds = {};
  final List<String> connected = [];

  @override
  Future<Map<String, Map<String, dynamic>>> getFeeds() async => feeds;

  @override
  Future<String> connect(String kind) async {
    connected.add(kind);
    feeds[kind] = {
      'id': 'id-$kind',
      'kind': kind,
      'include_tasks': true,
      'include_goals': true,
      'include_appointments': true,
      'discreet_titles': false,
    };
    return 'https://exemplo.test/$kind.ics';
  }

  @override
  Future<void> setOption(String id, String column, bool value) async {
    feeds.values.firstWhere((feed) => feed['id'] == id)[column] = value;
  }
}

Future<void> _open(
  WidgetTester tester,
  _FakeRepository repository, {
  String? trail,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalendarConnectDialog(
          repository: repository,
          womenTrailTitle: trail,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('o link aponta para a função do calendário', () {
    expect(
      CalendarFeedRepository.linkFor('abc'),
      endsWith('/functions/v1/calendar-feed/abc.ics'),
    );
  });

  testWidgets('sem trilha, só o planner pode ser conectado', (tester) async {
    await _open(tester, _FakeRepository());

    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Conectar'), findsOneWidget);
  });

  testWidgets('conectar mostra o link e as opções', (tester) async {
    final repository = _FakeRepository();
    await _open(tester, repository);

    await tester.tap(find.text('Conectar'));
    await tester.pumpAndSettle();

    expect(repository.connected, [CalendarFeedKind.planner]);
    expect(find.text('Adicionar ao calendário'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);

    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();

    expect(
      repository.feeds[CalendarFeedKind.planner]!['include_goals'],
      isFalse,
    );
  });

  testWidgets('a trilha fica separada e só conecta quando pedido', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _open(tester, repository, trail: 'Ciclo menstrual');

    expect(find.text('Ciclo menstrual'), findsOneWidget);
    expect(find.text('Conectar'), findsNWidgets(2));

    await tester.tap(find.text('Conectar').last);
    await tester.pumpAndSettle();

    expect(repository.connected, [CalendarFeedKind.womenHealth]);
    expect(find.text('Usar nomes discretos'), findsOneWidget);
  });

  testWidgets('quem já conectou não vê o link de novo', (tester) async {
    final repository = _FakeRepository();
    await repository.connect(CalendarFeedKind.planner);
    await _open(tester, repository);

    expect(find.text('Adicionar ao calendário'), findsNothing);
    expect(find.text('Gerar novo link'), findsOneWidget);
    expect(find.text('Desconectar'), findsOneWidget);
  });
}
