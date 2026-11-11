import 'package:supabase_flutter/supabase_flutter.dart';

import 'women_diary_repository.dart';

/// Dados do modo Saúde da mulher. As regras do banco só deixam a própria
/// usuária ler e alterar estas tabelas.
class WomenHealthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const _profiles = 'tb_women_health_profiles';
  static const _checkIns = 'tb_women_health_check_ins';
  static const _logs = 'tb_women_health_logs';

  /// Registros de menstruação, tentativas e testes (mais novos primeiro).
  Future<List<Map<String, dynamic>>> getLogs(String userId) async {
    final rows = await _client
        .from(_logs)
        .select('day, kind, value, note')
        .eq('user_id', userId)
        .order('day', ascending: false)
        .limit(2000);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<void> saveLog(
    String userId,
    String day,
    String kind, {
    String? value,
  }) {
    return _client.from(_logs).upsert({
      'user_id': userId,
      'day': day,
      'kind': kind,
      'value': value,
    }, onConflict: 'user_id,day,kind');
  }

  Future<void> deleteLog(String userId, String day, String kind) {
    return _client
        .from(_logs)
        .delete()
        .eq('user_id', userId)
        .eq('day', day)
        .eq('kind', kind);
  }

  Future<Map<String, dynamic>?> getProfile(String userId) {
    return _client.from(_profiles).select().eq('user_id', userId).maybeSingle();
  }

  /// Humor de cada dia ('2026-11-04' => 'Calma').
  Future<Map<String, String>> getCheckIns(String userId) async {
    final rows = await _client
        .from(_checkIns)
        .select('day, mood')
        .eq('user_id', userId);
    return {
      for (final row in rows) row['day'] as String: row['mood'] as String,
    };
  }

  Future<void> saveProfile({
    required String userId,
    required String? trail,
    required String? lastPeriod,
    required int cycleLength,
    required Map<String, String> answers,
    DateTime? consentAt,
  }) {
    return _client.from(_profiles).upsert({
      'user_id': userId,
      'trail': trail,
      'last_period': lastPeriod,
      'cycle_length': cycleLength,
      'answers': answers,
      if (consentAt != null) 'consent_at': consentAt.toUtc().toIso8601String(),
    });
  }

  Future<void> saveCheckIn(String userId, String day, String mood) {
    return _client.from(_checkIns).upsert({
      'user_id': userId,
      'day': day,
      'mood': mood,
    });
  }

  /// Sintomas, energia e sono do dia (o texto do dia vai para o diário). Gravado à parte: se o banco
  /// ainda não tiver essas colunas, o humor continua salvo.
  Future<bool> saveCheckInDetails(
    String userId,
    String day, {
    required List<String> symptoms,
    required int? energy,
    required String? sleep,
  }) async {
    try {
      await _client
          .from(_checkIns)
          .update({'symptoms': symptoms, 'energy': energy, 'sleep': sleep})
          .eq('user_id', userId)
          .eq('day', day);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Detalhes guardados do dia, ou null se não houver (ou o banco ainda não
  /// tiver as colunas).
  Future<Map<String, dynamic>?> getCheckInDetails(
    String userId,
    String day,
  ) async {
    try {
      return await _client
          .from(_checkIns)
          .select('symptoms, energy, sleep')
          .eq('user_id', userId)
          .eq('day', day)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCheckIn(String userId, String day) {
    return _client
        .from(_checkIns)
        .delete()
        .eq('user_id', userId)
        .eq('day', day);
  }

  /// Apaga tudo da Saúde da Mulher da usuária, inclusive o "Meu diário".
  Future<void> deleteAll(String userId) async {
    await WomenDiaryRepository().deleteAll(userId);
    await _client.from(_checkIns).delete().eq('user_id', userId);
    try {
      await _client.from(_logs).delete().eq('user_id', userId);
    } catch (_) {}
    await _client.from(_profiles).delete().eq('user_id', userId);
  }
}
