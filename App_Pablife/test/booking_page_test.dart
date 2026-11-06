import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/professional_model.dart';
import 'package:pablife/infra/models/professional_schedule_slot.dart';
import 'package:pablife/infra/models/professional_with_user_model.dart';
import 'package:pablife/infra/models/user_model.dart';
import 'package:pablife/modules/professionals/booking/booking_controller.dart';
import 'package:pablife/modules/professionals/booking/booking_page.dart';
import 'package:pablife/modules/women_health/women_health_data.dart';
import 'package:pablife/shared/themes/app_palette.dart';

const _mobile = Size(390, 844);
const _small = Size(320, 640);
const _desktop = Size(1440, 1000);
const _notebook = Size(920, 800);

/// "Amanhã" às [hour]h, sempre no futuro para o teste não envelhecer.
DateTime _at(int days, int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days, hour);
}

ProfessionalScheduleSlot _slot(String id, DateTime start) =>
    ProfessionalScheduleSlot(
      id: id,
      professionalId: 'p1',
      startAt: start,
      finishAt: start.add(const Duration(hours: 1)),
      timezone: 'America/Fortaleza',
    );

List<ProfessionalScheduleSlot> _slots() => [
  for (final (index, hour) in [8, 9, 10, 11, 13, 14, 15, 16, 18, 19].indexed)
    _slot('s$index', _at(2, hour)),
  _slot('x', _at(3, 9)),
  _slot('y', _at(40, 9)),
];

ProfessionalWithUserModel _professional() => ProfessionalWithUserModel(
  professional: ProfessionalModel.fromMap({
    'id': 'p1',
    'user_id': 'u1',
    'type': 'psychologist',
  }),
  user: UserModel.fromMap({
    'id': 'u1',
    'full_name': 'Maria Aparecida dos Santos Vasconcelos Pereira',
    'email': 'ana@exemplo.test',
    'phone': '',
    'cpf_document': '',
    'role': 'professional',
    'status': 'active',
  }),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  List<ProfessionalScheduleSlot>? slots,
  bool women = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Get.put(
    BookingController(
      professional: _professional(),
      loadSlots: () async => slots ?? _slots(),
      book: (_) async => null,
      notify: (_) {},
      womenMode: women,
      cyclePhaseOn: women
          ? (day) => day.day.isEven
                ? const WomenCyclePhase(
                    WomenCycleKind.fertile,
                    'Previsão de período fértil',
                  )
                : const WomenCyclePhase(
                    WomenCycleKind.menstruation,
                    'Previsão de menstruação',
                  )
          : null,
    ),
  );

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(fontFamily: 'InstrumentSans'),
      home: const BookingPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('InstrumentSans')
      ..addFont(
        rootBundle.load(
          'assets/fonts/Instrument_Sans/static/InstrumentSans-Regular.ttf',
        ),
      );
    await font.load();
  });

  setUp(() => Get.testMode = true);
  tearDown(() {
    Get.reset();
    AppPalette.isRose = false;
  });

  for (final (name, size) in [
    ('celular', _mobile),
    ('celular pequeno', _small),
    ('notebook', _notebook),
    ('computador', _desktop),
  ]) {
    for (final women in [false, true]) {
      final label = women ? 'Saúde da mulher' : 'normal';

      testWidgets('escolher e confirmar sem quebrar: $name, $label', (
        tester,
      ) async {
        AppPalette.isRose = women;
        await _pump(tester, size, women: women);

        await tester.ensureVisible(find.text('08:00'));
        await tester.tap(find.text('08:00'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Confira e confirme'), findsOneWidget);
        expect(
          find.text('Seu ciclo neste dia'),
          women ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Confirmar agendamento'));
        await tester.tap(find.text('Confirmar agendamento'));
        await tester.pumpAndSettle();
        expect(find.text('Consulta agendada!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('abrir a tela pela rota do app não dá erro', (tester) async {
    String? result;
    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(
            name: '/',
            page: () => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await BookingPage.open(_professional());
                },
                child: const Text('Agendar'),
              ),
            ),
          ),
          GetPage(
            name: BookingPage.route,
            page: () => Scaffold(
              body: TextButton(
                onPressed: () => Get.back(result: 'change'),
                child: const Text('Trocar'),
              ),
            ),
          ),
        ],
        initialRoute: '/',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Trocar'));
    await tester.pumpAndSettle();
    expect(result, 'change');
  });

  testWidgets('no computador, "Quero este" pega o primeiro horário', (
    tester,
  ) async {
    await _pump(tester, _desktop);

    await tester.tap(find.text('Quero este'));
    await tester.pumpAndSettle();

    expect(Get.find<BookingController>().selectedSlot!.id, 's0');
  });

  testWidgets('no celular, o mês inteiro abre e fecha', (tester) async {
    await _pump(tester, _mobile);

    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(find.text('Sem horários'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Sem horários'), findsNothing);
  });

  testWidgets('sem nenhum horário, avisa em vez de ficar em branco', (
    tester,
  ) async {
    await _pump(tester, _desktop, slots: []);

    expect(find.text('Sem horários livres no momento'), findsOneWidget);
    expect(find.text('Quero este'), findsNothing);
  });

  testWidgets('o aviso do ciclo aparece só no modo Saúde da mulher', (
    tester,
  ) async {
    await _pump(tester, _desktop);
    expect(find.textContaining('método contraceptivo'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    Get.reset();

    AppPalette.isRose = true;
    await _pump(tester, _desktop, women: true);
    expect(find.textContaining('método contraceptivo'), findsOneWidget);
    expect(find.text('Mostrar meu ciclo no calendário'), findsOneWidget);
  });
}
