import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/models/patient_record_model.dart';
import 'package:pablife/infra/models/professional_appointment_model.dart';
import 'package:pablife/shared/utils/consultation_rules.dart';

final _now = DateTime.utc(2026, 11, 20, 12);
final _beforeCutoff = DateTime.utc(2026, 11, 8, 12);
final _afterCutoff = DateTime.utc(2026, 11, 10, 12);

ProfessionalAppointmentModel _appointment({
  required Duration startsIn,
  required DateTime createdAt,
  AppointmentStatus status = AppointmentStatus.scheduled,
}) {
  final start = _now.add(startsIn);
  return ProfessionalAppointmentModel(
    id: 'a',
    scheduledBy: 'u',
    professionalId: 'p',
    patientId: 'u',
    patientName: 'Paciente',
    appointmentTimeId: 't',
    startOfScheduledWindow: start,
    endOfScheduledWindow: start.add(const Duration(hours: 1)),
    startAt: start,
    status: status,
    timezone: 'America/Fortaleza',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('consultas marcadas depois da data de corte', () {
    test('remarca até 3 horas antes', () {
      expect(
        ConsultationRules.canReschedule(
          _appointment(
            startsIn: const Duration(hours: 4),
            createdAt: _afterCutoff,
          ),
          now: _now,
        ),
        isTrue,
      );
      expect(
        ConsultationRules.canReschedule(
          _appointment(
            startsIn: const Duration(hours: 2),
            createdAt: _afterCutoff,
          ),
          now: _now,
        ),
        isFalse,
      );
    });

    test('cancela até a hora da consulta, sem devolver com menos de 24 h', () {
      final soon = _appointment(
        startsIn: const Duration(hours: 5),
        createdAt: _afterCutoff,
      );
      expect(ConsultationRules.canCancel(soon, now: _now), isTrue);
      expect(
        ConsultationRules.cancelReturnsToBalance(soon, now: _now),
        isFalse,
      );

      final later = _appointment(
        startsIn: const Duration(hours: 30),
        createdAt: _afterCutoff,
      );
      expect(
        ConsultationRules.cancelReturnsToBalance(later, now: _now),
        isTrue,
      );

      final started = _appointment(
        startsIn: const Duration(minutes: -10),
        createdAt: _afterCutoff,
      );
      expect(ConsultationRules.canCancel(started, now: _now), isFalse);
    });
  });

  group('consultas marcadas antes da data de corte', () {
    test('remarcar e cancelar seguem as 24 horas de antes', () {
      final soon = _appointment(
        startsIn: const Duration(hours: 20),
        createdAt: _beforeCutoff,
      );
      expect(ConsultationRules.canReschedule(soon, now: _now), isFalse);
      expect(ConsultationRules.canCancel(soon, now: _now), isFalse);

      final later = _appointment(
        startsIn: const Duration(hours: 30),
        createdAt: _beforeCutoff,
      );
      expect(ConsultationRules.canReschedule(later, now: _now), isTrue);
      expect(ConsultationRules.canCancel(later, now: _now), isTrue);
      expect(
        ConsultationRules.cancelReturnsToBalance(later, now: _now),
        isTrue,
      );
    });
  });

  test('só consulta agendada pode ser remarcada ou cancelada', () {
    final done = _appointment(
      startsIn: const Duration(days: 3),
      createdAt: _afterCutoff,
      status: AppointmentStatus.completed,
    );
    expect(ConsultationRules.canReschedule(done, now: _now), isFalse);
    expect(ConsultationRules.canCancel(done, now: _now), isFalse);
  });

  test('problema técnico vai e volta do banco', () {
    expect(
      AppointmentStatus.fromString('technical_issue'),
      AppointmentStatus.technicalIssue,
    );
    expect(AppointmentStatus.technicalIssue.toDbString(), 'technical_issue');
  });

  test('anotação sem visibilidade segue o tipo; com visibilidade, o banco', () {
    Map<String, dynamic> row(String type, [String? visibility]) => {
      'id': 'r',
      'patient_id': 'p',
      'type': type,
      'title': 't',
      'description': 'd',
      'created_at': '2026-11-10T12:00:00Z',
      'updated_at': '2026-11-10T12:00:00Z',
      'visibility': ?visibility,
    };

    expect(PatientRecordModel.fromMap(row('meal_plan')).isShared, isTrue);
    expect(PatientRecordModel.fromMap(row('observation')).isShared, isFalse);
    expect(
      PatientRecordModel.fromMap(row('observation', 'shared')).isShared,
      isTrue,
    );
    expect(
      PatientRecordModel.fromMap(
        row('meal_plan', 'private'),
      ).toMap()['visibility'],
      'private',
    );
  });
}
