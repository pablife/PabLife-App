import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/models/professional_appointment_model.dart';

void main() {
  test('consulta de horário semanal termina na data dela, não hoje', () {
    // Horário que se repete toda semana: due_at vazio.
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final end = start.add(const Duration(hours: 1));
    final model = ProfessionalAppointmentModel.fromMap({
      'id': 'a1',
      'scheduled_by': 'u1',
      'professional_id': 'p1',
      'appointment_time_id': 't1',
      'status': 'scheduled',
      'start_of_scheduled_window': start.toIso8601String(),
      'end_of_scheduled_window': end.toIso8601String(),
      'appointment_time': {
        'due_at': null,
        'start_time_at': '08:00:00',
        'finish_time_at': '09:00:00',
        'timezone': 'America/Sao_Paulo',
      },
    });

    expect(model.finishAt, end.toLocal());
    expect(model.finishAt!.isAfter(DateTime.now()), isTrue);
  });

  test('consulta de horário avulso usa a data do horário', () {
    final model = ProfessionalAppointmentModel.fromMap({
      'id': 'a2',
      'status': 'scheduled',
      'appointment_time': {
        'due_at': '2030-01-15',
        'start_time_at': '10:00:00',
        'finish_time_at': '11:00:00',
        'timezone': 'America/Sao_Paulo',
      },
    });

    expect(model.finishAt, DateTime(2030, 1, 15, 11));
  });
}
