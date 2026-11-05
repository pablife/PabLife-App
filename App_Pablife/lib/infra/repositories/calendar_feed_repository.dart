import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/env_service.dart';

/// Tipos de calendário que a pessoa pode assinar. O valor é o gravado no banco.
abstract final class CalendarFeedKind {
  static const planner = 'planner';
  static const womenHealth = 'women_health';
}

/// Links secretos para ver o PabLife no Calendário da Apple, Google ou Outlook.
class CalendarFeedRepository {
  SupabaseClient get _client => Supabase.instance.client;

  static const _table = 'tb_calendar_feeds';

  /// O código do link nunca volta do banco: só existe na resposta de [connect].
  static const _columns =
      'id, kind, include_tasks, include_goals, include_appointments, '
      'discreet_titles, last_fetched_at';

  Future<Map<String, Map<String, dynamic>>> getFeeds() async {
    final rows = await _client.from(_table).select(_columns);
    return {for (final row in rows) row['kind'] as String: row};
  }

  /// Cria o link, ou troca o atual (o antigo para de funcionar).
  Future<String> connect(String kind) async {
    final token = await _client.rpc<String>(
      'connect_calendar_feed',
      params: {'p_kind': kind},
    );
    return linkFor(token);
  }

  Future<void> setOption(String id, String column, bool value) {
    return _client.from(_table).update({column: value}).eq('id', id);
  }

  Future<void> disconnect(String id) {
    return _client.from(_table).delete().eq('id', id);
  }

  static String linkFor(String token) =>
      '${EnvVariables.url}/functions/v1/calendar-feed/$token.ics';
}
