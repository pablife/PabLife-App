import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef DailyVerse = ({String reference, String text, String? translation});

/// Versículo do dia (cadastrado pelo admin; um por dia, igual para todos).
class DailyVerseRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<DailyVerse?> today() async {
    try {
      final rows = await _client.rpc('verse_of_the_day') as List;
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first as Map);
      return (
        reference: row['reference'] as String,
        text: row['text'] as String,
        translation: row['translation'] as String?,
      );
    } catch (e) {
      debugPrint('Versículo do dia indisponível: $e');
      return null;
    }
  }
}
