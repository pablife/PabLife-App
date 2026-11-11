import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestação (Saúde da Mulher). As regras do banco só deixam a própria
/// usuária ler e alterar; o profissional lê só os registros compartilhados
/// das pacientes dele. A semana atual vem calculada do banco.
class PregnancyRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const _pregnancies = 'tb_pregnancies';
  static const _records = 'tb_pregnancy_records';
  static const _photos = 'pregnancy-photos';

  /// Gestação ativa com semana, dias e trimestre (get_my_pregnancy).
  Future<Map<String, dynamic>?> current() async {
    final rows = await _client.rpc('get_my_pregnancy') as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> start(String userId, String dum) {
    return _client.from(_pregnancies).insert({'user_id': userId, 'dum': dum});
  }

  Future<void> updateDum(String pregnancyId, String dum) {
    return _client
        .from(_pregnancies)
        .update({'dum': dum})
        .eq('id', pregnancyId);
  }

  /// Encerra: os avisos pendentes deixam de ser enviados. Nada é apagado.
  Future<void> end(String pregnancyId) {
    return _client
        .from(_pregnancies)
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pregnancyId);
  }

  /// Conteúdo das semanas 4 a 40 (textos só quando revisados).
  Future<List<Map<String, dynamic>>> weeks() async {
    final rows = await _client.rpc('get_pregnancy_weeks') as List<dynamic>;
    return [for (final r in rows) Map<String, dynamic>.from(r as Map)];
  }

  /// Registros da gestação, do mais novo para o mais antigo.
  Future<List<Map<String, dynamic>>> records(String pregnancyId) async {
    final rows = await _client
        .from(_records)
        .select()
        .eq('pregnancy_id', pregnancyId)
        .order('record_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1000);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<void> saveRecord(Map<String, dynamic> data) {
    return _client.from(_records).insert(data);
  }

  Future<void> deleteRecord(String id) {
    return _client.from(_records).delete().eq('id', id);
  }

  /// Envia a foto para "id-da-usuária/arquivo" no bucket privado e devolve o
  /// caminho guardado no registro.
  Future<String> uploadPhoto(
    String userId,
    Uint8List bytes,
    String extension,
  ) async {
    final ext = extension.toLowerCase() == 'jpg' ? 'jpeg' : extension;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.${extension.toLowerCase()}';
    await _client.storage
        .from(_photos)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );
    return path;
  }

  /// Link temporário (10 min) para ver a foto.
  Future<String> photoLink(String path) {
    return _client.storage.from(_photos).createSignedUrl(path, 600);
  }

  Future<void> removePhoto(String path) {
    return _client.storage.from(_photos).remove([path]);
  }
}
