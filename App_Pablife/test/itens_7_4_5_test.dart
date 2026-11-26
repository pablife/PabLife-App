import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/professional_appointment_model.dart';
import 'package:pablife/infra/models/professional_model.dart';
import 'package:pablife/modules/consultations/rating_prompt.dart';
import 'package:pablife/modules/professional_area/create_slot_request.dart';
import 'package:pablife/modules/professional_area/professional_area_controller.dart';
import 'package:pablife/modules/professional_area/professional_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

ProfessionalAppointmentModel _appt(
  String id,
  DateTime start,
  AppointmentStatus status,
) => ProfessionalAppointmentModel(
  id: id,
  scheduledBy: 'u1',
  professionalId: 'p1',
  patientId: 'u1',
  patientName: 'Paciente',
  appointmentTimeId: 't1',
  startOfScheduledWindow: start,
  endOfScheduledWindow: start.add(const Duration(minutes: 50)),
  startAt: start,
  status: status,
  timezone: 'America/Fortaleza',
  createdAt: start,
  updatedAt: start,
);

ProfessionalModel _pro(String status) => ProfessionalModel(
  id: 'p1',
  userId: 'u1',
  type: 'psychologist',
  validationDocumentUrl: '',
  validationStatus: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://exemplo.supabase.co', anonKey: 'x');
  });

  group('item 5: pedido de avaliação', () {
    final now = DateTime(2026, 11, 26, 15);

    test('escolhe a concluída mais recente, sem nota, dos últimos 7 dias', () {
      final recent = [
        _appt(
          'velha',
          now.subtract(const Duration(days: 9)),
          AppointmentStatus.completed,
        ),
        _appt(
          'ontem',
          now.subtract(const Duration(days: 1)),
          AppointmentStatus.completed,
        ),
        _appt(
          'anteontem',
          now.subtract(const Duration(days: 2)),
          AppointmentStatus.completed,
        ),
        _appt(
          'faltou',
          now.subtract(const Duration(hours: 3)),
          AppointmentStatus.noShow,
        ),
        _appt(
          'agendada',
          now.subtract(const Duration(hours: 2)),
          AppointmentStatus.scheduled,
        ),
        _appt(
          'cancelada',
          now.subtract(const Duration(hours: 5)),
          AppointmentStatus.cancelled,
        ),
      ];
      final picked = RatingPrompt.pick(
        recent: recent,
        rated: const {},
        dismissed: const {},
        now: now,
      );
      expect(picked?.id, 'ontem');
    });

    test('pula as já avaliadas e as que a pessoa dispensou', () {
      final recent = [
        _appt(
          'a',
          now.subtract(const Duration(days: 1)),
          AppointmentStatus.completed,
        ),
        _appt(
          'b',
          now.subtract(const Duration(days: 2)),
          AppointmentStatus.completed,
        ),
        _appt(
          'c',
          now.subtract(const Duration(days: 3)),
          AppointmentStatus.completed,
        ),
      ];
      expect(
        RatingPrompt.pick(
          recent: recent,
          rated: {'a'},
          dismissed: {'b'},
          now: now,
        )?.id,
        'c',
      );
      expect(
        RatingPrompt.pick(
          recent: recent,
          rated: {'a', 'c'},
          dismissed: {'b'},
          now: now,
        ),
        isNull,
      );
    });
  });

  group('item 4: sem horários abertos', () {
    tearDown(Get.reset);

    test('o aviso só aparece para aprovado com zero horários', () {
      Get.testMode = true;
      final c = ProfessionalAreaController()..professional = _pro('approved');
      c.openSlots = 0;
      expect(c.showNoSlotsWarning, isTrue);
      c.openSlots = 3;
      expect(c.showNoSlotsWarning, isFalse);
      c.openSlots = null; // não deu para saber: sem aviso
      expect(c.showNoSlotsWarning, isFalse);
      c
        ..professional = _pro('pending')
        ..openSlots = 0;
      expect(c.showNoSlotsWarning, isFalse);
    });

    test('pedido de "Criar horário" vale uma vez e avisa quem escuta', () {
      var heard = 0;
      void listener() => heard++;
      CreateSlotRequest.tick.addListener(listener);
      CreateSlotRequest.ask();
      expect(heard, 1);
      expect(CreateSlotRequest.take(), isTrue);
      expect(CreateSlotRequest.take(), isFalse);
      CreateSlotRequest.tick.removeListener(listener);
    });

    testWidgets('cartão mostra o aviso e o botão Criar horário', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NoSlotsWarning(onCreate: () => tapped++)),
        ),
      );
      expect(find.text('Você não tem horários abertos'), findsOneWidget);
      expect(
        find.textContaining('Os pacientes não conseguem marcar'),
        findsOneWidget,
      );
      await tester.tap(find.text('Criar horário'));
      expect(tapped, 1);
    });
  });
}
