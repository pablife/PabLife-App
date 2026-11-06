import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/professional_model.dart';
import 'package:pablife/infra/models/professional_schedule_slot.dart';
import 'package:pablife/infra/models/professional_with_user_model.dart';
import 'package:pablife/infra/models/user_model.dart';
import 'package:pablife/modules/professionals/booking/booking_controller.dart';
import 'package:pablife/modules/women_health/women_health_data.dart';

final _now = DateTime(2026, 11, 6, 15);

ProfessionalScheduleSlot _slot(String id, DateTime start) =>
    ProfessionalScheduleSlot(
      id: id,
      professionalId: 'p1',
      startAt: start,
      finishAt: start.add(const Duration(hours: 1)),
      timezone: 'America/Fortaleza',
    );

ProfessionalWithUserModel _professional() {
  return ProfessionalWithUserModel(
    professional: ProfessionalModel.fromMap({
      'id': 'p1',
      'user_id': 'u1',
      'type': 'psychologist',
    }),
    user: UserModel.fromMap({
      'id': 'u1',
      'full_name': 'Ana Souza',
      'email': 'ana@exemplo.test',
      'phone': '',
      'cpf_document': '',
      'role': 'professional',
      'status': 'active',
    }),
  );
}

BookingController _controller(
  List<ProfessionalScheduleSlot> slots, {
  Future<String?> Function(ProfessionalScheduleSlot)? book,
  WomenCyclePhase? Function(DateTime)? cyclePhaseOn,
}) {
  return BookingController(
    professional: _professional(),
    loadSlots: () async => List.of(slots),
    book: book ?? (_) async => null,
    now: () => _now,
    notify: (_) {},
    womenMode: cyclePhaseOn != null,
    cyclePhaseOn: cyclePhaseOn,
  );
}

Future<BookingController> _ready(BookingController controller) async {
  controller.viewMonth = DateTime(2026, 11);
  await controller.load();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  test('abre no primeiro dia com horário, sem horários passados', () async {
    final c = await _ready(
      _controller([
        _slot('a', DateTime(2026, 11, 6, 9)),
        _slot('b', DateTime(2026, 11, 7, 10)),
        _slot('c', DateTime(2026, 11, 7, 8)),
      ]),
    );

    expect(c.selectedDay, DateTime(2026, 11, 7));
    expect(c.selectedDaySlots.map((s) => s.id), ['c', 'b']);
    expect(c.firstSlot!.id, 'c');
    expect(c.slotsOn(DateTime(2026, 11, 6)), isEmpty);
  });

  test('o mesmo horário repetido aparece uma vez só', () async {
    final start = DateTime(2026, 11, 7, 10);
    final c = await _ready(_controller([_slot('a', start), _slot('b', start)]));

    expect(c.selectedDaySlots, hasLength(1));
  });

  test('separa os horários em manhã, tarde e noite', () async {
    final c = await _ready(
      _controller([
        _slot('m', DateTime(2026, 11, 7, 11)),
        _slot('t', DateTime(2026, 11, 7, 12)),
        _slot('t2', DateTime(2026, 11, 7, 17)),
        _slot('n', DateTime(2026, 11, 7, 18)),
      ]),
    );

    expect(c.periods.map((p) => (p.name, p.slots.map((s) => s.id).toList())), [
      ('Manhã', ['m']),
      ('Tarde', ['t', 't2']),
      ('Noite', ['n']),
    ]);
  });

  test('não mostra período sem horário', () async {
    final c = await _ready(
      _controller([_slot('n', DateTime(2026, 11, 7, 19))]),
    );

    expect(c.periods.map((p) => p.name), ['Noite']);
  });

  test('"Quero este" escolhe o primeiro horário, mesmo em outro mês', () async {
    final c = await _ready(
      _controller([
        _slot('a', DateTime(2026, 12, 2, 9)),
        _slot('b', DateTime(2026, 12, 3, 9)),
      ]),
    );
    c.selectDay(DateTime(2026, 12, 3));

    c.useFirstSlot();

    expect(c.selectedSlot!.id, 'a');
    expect(c.selectedDay, DateTime(2026, 12, 2));
    expect(c.viewMonth, DateTime(2026, 12));
  });

  test('dia sem horário não pode ser escolhido', () async {
    final c = await _ready(_controller([_slot('a', DateTime(2026, 11, 7, 9))]));

    c.selectDay(DateTime(2026, 11, 8));

    expect(c.selectedDay, DateTime(2026, 11, 7));
  });

  test('trocar de dia limpa o horário escolhido', () async {
    final slots = [
      _slot('a', DateTime(2026, 11, 7, 9)),
      _slot('b', DateTime(2026, 11, 9, 9)),
    ];
    final c = await _ready(_controller(slots));
    c.selectSlot(c.selectedDaySlots.first);

    c.selectDay(DateTime(2026, 11, 9));

    expect(c.selectedSlot, isNull);
  });

  test('vai ao próximo dia com horários', () async {
    final c = await _ready(
      _controller([
        _slot('a', DateTime(2026, 11, 7, 9)),
        _slot('b', DateTime(2026, 12, 1, 9)),
      ]),
    );

    c.goToNextDayWithSlots();

    expect(c.selectedDay, DateTime(2026, 12, 1));
    expect(c.viewMonth, DateTime(2026, 12));
  });

  test('o mês não volta antes de hoje nem passa dos 180 dias', () async {
    final c = await _ready(_controller([_slot('a', DateTime(2026, 11, 7, 9))]));

    c.changeMonth(-1);
    expect(c.viewMonth, DateTime(2026, 11));

    for (var i = 0; i < 12; i++) {
      c.changeMonth(1);
    }
    expect(c.viewMonth, DateTime(2027, 5));
  });

  test('sem horário escolhido não vai para a confirmação', () async {
    final c = await _ready(_controller([_slot('a', DateTime(2026, 11, 7, 9))]));

    c.toConfirm();

    expect(c.step, BookingStep.pick);
  });

  test('confirmar marca o horário escolhido', () async {
    ProfessionalScheduleSlot? booked;
    final c = await _ready(
      _controller(
        [_slot('a', DateTime(2026, 11, 7, 9))],
        book: (slot) async {
          booked = slot;
          return null;
        },
      ),
    );
    c.useFirstSlot();
    c.toConfirm();

    await c.confirm();

    expect(booked!.id, 'a');
    expect(c.step, BookingStep.done);
  });

  test('se o horário foi ocupado, volta e mostra o que restou', () async {
    final slots = [
      _slot('a', DateTime(2026, 11, 7, 9)),
      _slot('b', DateTime(2026, 11, 7, 10)),
    ];
    final c = await _ready(
      _controller(
        slots,
        book: (_) async {
          slots.removeAt(0);
          return 'Este horário não está mais disponível.';
        },
      ),
    );
    c.useFirstSlot();
    c.toConfirm();

    await c.confirm();

    expect(c.step, BookingStep.pick);
    expect(c.selectedSlot, isNull);
    expect(c.selectedDaySlots.map((s) => s.id), ['b']);
  });

  test('falha ao carregar não vira agenda vazia', () async {
    final c = BookingController(
      professional: _professional(),
      loadSlots: () async => throw Exception('sem rede'),
      book: (_) async => null,
      now: () => _now,
      notify: (_) {},
    );
    c.viewMonth = DateTime(2026, 11);

    await c.load();

    expect(c.loadFailed, isTrue);
    expect(c.loading, isFalse);
  });

  test('o ciclo some do calendário, mas continua na confirmação', () async {
    const phase = WomenCyclePhase(
      WomenCycleKind.fertile,
      'Previsão de período fértil',
    );
    final c = await _ready(
      _controller([
        _slot('a', DateTime(2026, 11, 7, 9)),
      ], cyclePhaseOn: (_) => phase),
    );
    final day = DateTime(2026, 11, 7);
    expect(c.visibleCyclePhaseOn(day), phase);

    c.toggleCycle();

    expect(c.visibleCyclePhaseOn(day), isNull);
    expect(c.cyclePhaseOn(day), phase);
  });
}
