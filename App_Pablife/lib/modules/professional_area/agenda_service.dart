import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infra/models/professional_schedule_slot.dart';
import '../../infra/repositories/professional_repository.dart';

/// Horário de uma semana que repete e foi bloqueado só num dia (exceção).
/// Tocar nele libera de novo.
class BlockedSlot {
  final String exceptionId;
  final String appointmentTimeId;
  final DateTime startAt;

  const BlockedSlot({
    required this.exceptionId,
    required this.appointmentTimeId,
    required this.startAt,
  });
}

/// Períodos da "Semana padrão" (canvas PA): sessões online de 50 min, uma
/// por hora, como os horários que já existem.
enum WeekPeriod {
  morning('Manhã', '08:00–12:00', [8, 9, 10, 11]),
  afternoon('Tarde', '14:00–18:00', [14, 15, 16, 17]),
  evening('Noite', '18:00–21:00', [18, 19, 20]);

  final String label;
  final String range;
  final List<int> hours;

  const WeekPeriod(this.label, this.range, this.hours);
}

/// Semana que repete: dia da semana (0 = domingo … 6 = sábado) → horários
/// "HH:mm" → id do horário.
typedef WeekPattern = Map<int, Map<String, String>>;

/// Ações da agenda do profissional que não existiam: bloquear um dia de um
/// horário que repete, liberar de novo e montar a semana padrão.
class AgendaService {
  SupabaseClient get _client => Supabase.instance.client;
  final _professionals = ProfessionalRepository();

  static String hhmm(int hour, [int minute = 0]) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Bloqueios (exceções) do período, por dia.
  Future<Map<DateTime, List<BlockedSlot>>> blocked({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final rows = await _client
          .from('tb_appointment_recurrence_exceptions')
          .select(
            'id, slot_date, time:tb_appointment_times!inner(id, professional_id, start_time_at, deleted_at)',
          )
          .eq('time.professional_id', professionalId)
          .isFilter('time.deleted_at', null)
          .isFilter('deleted_at', null)
          .gte('slot_date', fmt.format(start))
          .lt('slot_date', fmt.format(end));
      final out = <DateTime, List<BlockedSlot>>{};
      for (final row in rows) {
        final day = DateTime.parse(row['slot_date'] as String);
        final time = row['time'] as Map<String, dynamic>;
        final parts = (time['start_time_at'] as String).split(':');
        final startAt = DateTime(
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        out
            .putIfAbsent(DateTime(day.year, day.month, day.day), () => [])
            .add(
              BlockedSlot(
                exceptionId: row['id'] as String,
                appointmentTimeId: time['id'] as String,
                startAt: startAt,
              ),
            );
      }
      for (final list in out.values) {
        list.sort((a, b) => a.startAt.compareTo(b.startAt));
      }
      return out;
    } catch (e) {
      debugPrint('Bloqueios da agenda: $e');
      return {};
    }
  }

  /// Bloqueia só este dia de um horário que repete. Devolve erro ou null.
  Future<String?> blockDay(ProfessionalScheduleSlot slot) async {
    try {
      final local = slot.startAt.toLocal();
      await _client.from('tb_appointment_recurrence_exceptions').insert({
        'appointment_time_id': slot.id,
        'slot_date': DateFormat('yyyy-MM-dd').format(local),
      });
      return null;
    } on PostgrestException catch (e) {
      return 'Não foi possível bloquear: ${e.message}';
    }
  }

  /// Libera de novo um horário bloqueado.
  Future<String?> release(BlockedSlot blocked) async {
    try {
      await _client
          .from('tb_appointment_recurrence_exceptions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', blocked.exceptionId);
      return null;
    } on PostgrestException catch (e) {
      return 'Não foi possível liberar: ${e.message}';
    }
  }

  /// Cria um horário (avulso ou que repete toda semana).
  Future<String?> createSlot({
    required String professionalId,
    required DateTime startAt,
    required bool everyWeek,
  }) async {
    final response = everyWeek
        ? await _professionals.createRecurringScheduleSlot(
            professionalId: professionalId,
            startAt: startAt,
          )
        : await _professionals.createScheduleSlot(
            professionalId: professionalId,
            startAt: startAt,
          );
    if (response.success) return null;
    return response.message.replaceFirst('Exception: ', '');
  }

  /// Horários que repetem toda semana e ainda valem.
  Future<WeekPattern> weekPattern(String professionalId) async {
    final out = <int, Map<String, String>>{};
    try {
      final rows = await _client
          .from('tb_appointment_times')
          .select(
            'id, start_time_at, rule:tb_appointment_recurrence_rules!inner(week_select, end_at, deleted_at)',
          )
          .eq('professional_id', professionalId)
          .isFilter('deleted_at', null)
          .isFilter('rule.deleted_at', null);
      final now = DateTime.now();
      for (final row in rows) {
        final rule = row['rule'] as Map<String, dynamic>;
        final endAt = rule['end_at'] == null
            ? null
            : DateTime.tryParse(rule['end_at'].toString());
        if (endAt != null && endAt.isBefore(now)) continue;
        final weekday = (rule['week_select'] as num).toInt();
        final time = (row['start_time_at'] as String).substring(0, 5);
        out.putIfAbsent(weekday, () => {})[time] = row['id'] as String;
      }
    } catch (e) {
      debugPrint('Semana padrão: $e');
    }
    return out;
  }

  /// Próxima data (a partir de hoje) do dia da semana, no horário dado.
  static DateTime nextOccurrence(int weekday, String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final today = DateTime(now.year, now.month, now.day);
    var date = today.add(Duration(days: (weekday - now.weekday % 7 + 7) % 7));
    var at = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (at.isBefore(now)) {
      date = date.add(const Duration(days: 7));
      at = at.add(const Duration(days: 7));
    }
    return at;
  }

  /// Aplica a semana padrão: cria o que falta e encerra, a partir de agora,
  /// o que saiu. Consultas já marcadas continuam. Devolve os erros.
  Future<List<String>> saveWeekPattern({
    required String professionalId,
    required WeekPattern current,
    required Map<int, Set<String>> desired,
  }) async {
    final errors = <String>[];
    for (final entry in desired.entries) {
      for (final time in entry.value) {
        if (current[entry.key]?.containsKey(time) ?? false) continue;
        final error = await createSlot(
          professionalId: professionalId,
          startAt: nextOccurrence(entry.key, time),
          everyWeek: true,
        );
        if (error != null) errors.add(error);
      }
    }
    final now = DateTime.now().toUtc().toIso8601String();
    for (final entry in current.entries) {
      for (final time in entry.value.entries) {
        if (desired[entry.key]?.contains(time.key) ?? false) continue;
        try {
          final row = await _client
              .from('tb_appointment_times')
              .select('appointment_recurrence_rule_id')
              .eq('id', time.value)
              .single();
          await _client
              .from('tb_appointment_recurrence_rules')
              .update({'end_at': now})
              .eq('id', row['appointment_recurrence_rule_id'] as String);
        } on PostgrestException catch (e) {
          errors.add(e.message);
        }
      }
    }
    return errors;
  }
}
