import 'package:supabase_flutter/supabase_flutter.dart';

/// Dados do modo Saúde da mulher. As regras do banco só deixam a própria
/// usuária ler e alterar estas tabelas.
class WomenHealthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const _profiles = 'tb_women_health_profiles';
  static const _checkIns = 'tb_women_health_check_ins';

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

  Future<void> deleteCheckIn(String userId, String day) {
    return _client
        .from(_checkIns)
        .delete()
        .eq('user_id', userId)
        .eq('day', day);
  }

  Future<void> deleteAll(String userId) async {
    await _client.from(_checkIns).delete().eq('user_id', userId);
    await _client.from(_profiles).delete().eq('user_id', userId);
  }
}
