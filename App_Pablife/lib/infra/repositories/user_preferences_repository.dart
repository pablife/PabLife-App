import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Visual do app guardado no cadastro, para valer em qualquer aparelho.
/// A tabela só é lida pela própria pessoa.
class UserPreferencesRepository {
  SupabaseClient get _client => Supabase.instance.client;

  static const pablife = 'pablife';
  static const womenHealth = 'saude_mulher';

  /// Grava o visual escolhido. Falha aqui não atrapalha a troca no aparelho.
  Future<void> saveTheme({required bool rose}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('tb_user_preferences').upsert({
        'user_id': userId,
        'app_theme': rose ? womenHealth : pablife,
      });
    } catch (e) {
      debugPrint('Não foi possível guardar o visual: $e');
    }
  }

  /// Mostrar o "Versículo do dia" no Dashboard (ligado se nunca mudou).
  Future<bool> loadShowDailyVerse() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return true;
    try {
      final row = await _client
          .from('tb_user_preferences')
          .select('show_daily_verse')
          .eq('user_id', userId)
          .maybeSingle();
      return row?['show_daily_verse'] as bool? ?? true;
    } catch (e) {
      debugPrint('Preferência do versículo indisponível: $e');
      return true;
    }
  }

  Future<bool> saveShowDailyVerse(bool show) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client.from('tb_user_preferences').upsert({
        'user_id': userId,
        'show_daily_verse': show,
      });
      return true;
    } catch (e) {
      debugPrint('Não foi possível guardar a preferência do versículo: $e');
      return false;
    }
  }

  /// O visual guardado, ou null se a pessoa ainda não escolheu.
  Future<bool?> loadRoseTheme() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('tb_user_preferences')
        .select('app_theme')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return row['app_theme'] == womenHealth;
  }
}
