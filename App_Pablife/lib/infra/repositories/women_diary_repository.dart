import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/women_diary_entry.dart';

/// "Meu diário" da Saúde da Mulher. Pelas regras do banco, só a dona lê e
/// grava; a profissional vinculada só lê o que ela compartilhou.
class WomenDiaryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const table = 'tb_women_health_diary_entries';

  /// Anotações de um mês, da mais recente para a mais antiga.
  Future<List<WomenDiaryEntry>> listByMonth(String userId, DateTime month) {
    final first = DateTime(month.year, month.month);
    final next = DateTime(month.year, month.month + 1);
    return listBetween(userId, first, next);
  }

  /// Anotações com dia em [start, end).
  Future<List<WomenDiaryEntry>> listBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .gte('day', WomenDiaryEntry.dayKey(start))
        .lt('day', WomenDiaryEntry.dayKey(end))
        .order('day', ascending: false);
    return rows.map(WomenDiaryEntry.fromJson).toList();
  }

  /// Todas as anotações da usuária, da mais recente para a mais antiga.
  Future<List<WomenDiaryEntry>> listAll(String userId) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .order('day', ascending: false);
    return rows.map(WomenDiaryEntry.fromJson).toList();
  }

  Future<WomenDiaryEntry?> getByDay(String userId, DateTime day) async {
    final row = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .eq('day', WomenDiaryEntry.dayKey(day))
        .maybeSingle();
    return row == null ? null : WomenDiaryEntry.fromJson(row);
  }

  /// Cria ou atualiza a anotação do dia.
  Future<WomenDiaryEntry> upsert(WomenDiaryEntry entry) async {
    final row = await _client
        .from(table)
        .upsert(entry.toRow(), onConflict: 'user_id,day')
        .select()
        .single();
    return WomenDiaryEntry.fromJson(row);
  }

  /// Só o texto "Como foi meu dia?" (vindo do "Como estou hoje"), sem mexer
  /// no resto da anotação.
  Future<void> saveDayText(String userId, DateTime day, String? text) async {
    final clean = text?.trim();
    final existing = await getByDay(userId, day);
    if (existing == null) {
      if (clean == null || clean.isEmpty) return;
      await _client.from(table).insert({
        'user_id': userId,
        'day': WomenDiaryEntry.dayKey(day),
        'day_text': clean,
      });
      return;
    }
    await _client
        .from(table)
        .update({'day_text': clean == null || clean.isEmpty ? null : clean})
        .eq('user_id', userId)
        .eq('day', WomenDiaryEntry.dayKey(day));
  }

  Future<void> toggleShare(String userId, DateTime day, bool shared) {
    return _client
        .from(table)
        .update({'shared_with_professional': shared})
        .eq('user_id', userId)
        .eq('day', WomenDiaryEntry.dayKey(day));
  }

  /// Anotações que a paciente compartilhou (área da profissional).
  Future<List<WomenDiaryEntry>> listSharedByPatient(
    String patientUserId,
  ) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_id', patientUserId)
        .eq('shared_with_professional', true)
        .order('day', ascending: false);
    return rows.map(WomenDiaryEntry.fromJson).toList();
  }

  Future<void> deleteAll(String userId) {
    return _client.from(table).delete().eq('user_id', userId);
  }
}
