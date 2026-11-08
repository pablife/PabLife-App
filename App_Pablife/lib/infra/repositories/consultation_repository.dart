import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sala de vídeo, cancelamento com motivo e avaliação das consultas.
class ConsultationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Link da sala da consulta. Só vem para quem é da consulta, a partir de
  /// 15 minutos antes e até o fim; fora disso, null.
  Future<String?> meetingUrl(String appointmentId) async {
    try {
      final url = await _client.rpc(
        'get_appointment_meeting_url',
        params: {'p_appointment_id': appointmentId},
      );
      return url is String && url.isNotEmpty ? url : null;
    } catch (e) {
      debugPrint('Link da sala indisponível: $e');
      return null;
    }
  }

  /// Link da sala do próprio profissional (para editar no perfil).
  Future<String?> myMeetingUrl(String professionalId) async {
    try {
      final row = await _client
          .from('tb_professional_meeting_links')
          .select('meeting_url')
          .eq('professional_id', professionalId)
          .maybeSingle();
      return row?['meeting_url'] as String?;
    } catch (e) {
      debugPrint('Link da sala indisponível: $e');
      return null;
    }
  }

  /// Grava (ou apaga, se vazio) o link da sala. Devolve uma mensagem de erro
  /// ou null.
  Future<String?> saveMeetingUrl(String professionalId, String url) async {
    final value = url.trim();
    try {
      if (value.isEmpty) {
        await _client
            .from('tb_professional_meeting_links')
            .delete()
            .eq('professional_id', professionalId);
        return null;
      }
      if (!value.startsWith('https://')) {
        return 'O link da sala precisa começar com https://';
      }
      await _client.from('tb_professional_meeting_links').upsert({
        'professional_id': professionalId,
        'meeting_url': value,
      });
      return null;
    } catch (e) {
      debugPrint('Erro ao salvar link da sala: $e');
      return 'Não foi possível salvar o link da sala.';
    }
  }

  /// Cancela a própria consulta com o motivo escolhido. Devolve a mensagem
  /// de erro do banco (prazo etc.) ou null.
  Future<String?> cancelWithReason(String appointmentId, String reason) async {
    try {
      await _client
          .from('tb_appointments')
          .update({'status': 'cancelled', 'cancellation_reason': reason})
          .eq('id', appointmentId);
      return null;
    } on PostgrestException catch (e) {
      return e.message.contains('não pode') || e.message.contains('começou')
          ? e.message
          : 'Não foi possível cancelar a consulta.';
    } catch (_) {
      return 'Não foi possível cancelar a consulta.';
    }
  }

  /// Consultas já avaliadas pela pessoa (ids).
  Future<Set<String>> ratedAppointmentIds() async {
    try {
      final rows = await _client
          .from('tb_appointment_ratings')
          .select('appointment_id');
      return {for (final r in rows) r['appointment_id'] as String};
    } catch (e) {
      debugPrint('Avaliações indisponíveis: $e');
      return {};
    }
  }

  Future<String?> submitRating({
    required String appointmentId,
    required String professionalId,
    required int score,
    required List<String> highlights,
    required String? comment,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 'Entre na sua conta para avaliar.';
    try {
      await _client.from('tb_appointment_ratings').insert({
        'appointment_id': appointmentId,
        'user_id': userId,
        'professional_id': professionalId,
        'score': score,
        'highlights': highlights,
        'comment': (comment?.trim().isEmpty ?? true) ? null : comment!.trim(),
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'Você já avaliou esta consulta.';
      debugPrint('Erro ao avaliar: $e');
      return 'Não foi possível enviar a avaliação.';
    } catch (e) {
      debugPrint('Erro ao avaliar: $e');
      return 'Não foi possível enviar a avaliação.';
    }
  }
}
