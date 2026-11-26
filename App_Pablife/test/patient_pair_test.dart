import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/repositories/patient_record_repository.dart';

void main() {
  group('item 2: ficha do paciente pelo par', () {
    test('usa a ficha mais antiga do par quando existe', () async {
      var askedAppointment = false;
      final id = await PatientRecordRepository.resolvePatientId(
        byPair: () async => 'ficha-antiga',
        byAppointment: () async {
          askedAppointment = true;
          return 'ficha-da-consulta';
        },
      );
      expect(id, 'ficha-antiga');
      expect(askedAppointment, isFalse);
    });

    test('sem ficha do par, usa a ficha da consulta (como antes)', () async {
      final id = await PatientRecordRepository.resolvePatientId(
        byPair: () async => null,
        byAppointment: () async => 'ficha-da-consulta',
      );
      expect(id, 'ficha-da-consulta');
    });

    test('sem nenhuma ficha, devolve null', () async {
      expect(
        await PatientRecordRepository.resolvePatientId(
          byPair: () async => '',
          byAppointment: () async => null,
        ),
        isNull,
      );
      expect(
        await PatientRecordRepository.resolvePatientId(
          byPair: () async => null,
        ),
        isNull,
      );
    });
  });
}
