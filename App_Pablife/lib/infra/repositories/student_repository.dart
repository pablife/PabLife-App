
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Situação do desconto de estudante da pessoa logada.
enum StudentStatus { none, pending, approved, rejected }

/// Comprovante de estudante (desconto de 10%). O arquivo fica num lugar
/// privado, na pasta da própria pessoa; só ela e o admin conseguem abrir.
class StudentRepository {
  SupabaseClient get _client => Supabase.instance.client;

  static const bucket = 'student-proofs';

  Future<StudentStatus> myStatus() async {
    try {
      final value = await _client.rpc('my_student_status');
      return switch (value) {
        'pending' => StudentStatus.pending,
        'approved' => StudentStatus.approved,
        'rejected' => StudentStatus.rejected,
        _ => StudentStatus.none,
      };
    } catch (e) {
      debugPrint('Status de estudante indisponível: $e');
      return StudentStatus.none;
    }
  }

  /// Envia o arquivo e cria o pedido em análise. Devolve uma mensagem de
  /// erro, ou null se deu certo.
  Future<String?> submit({
    required String institution,
    required String course,
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 'Entre na sua conta para enviar o comprovante.';

    final ext = extension.toLowerCase() == 'jpeg'
        ? 'jpg'
        : extension.toLowerCase();
    final contentType = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    final path =
        '$userId/comprovante-${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } catch (e) {
      debugPrint('Erro ao enviar comprovante: $e');
      return 'Não foi possível enviar o arquivo. Tente de novo.';
    }

    try {
      await _client.from('tb_student_verifications').insert({
        'user_id': userId,
        'institution': institution.trim(),
        'course': course.trim(),
        'document_path': path,
      });
      return null;
    } on PostgrestException catch (e) {
      // Já existe um pedido em análise: troca o arquivo dele.
      if (e.code == '23505') {
        await _client
            .from('tb_student_verifications')
            .update({
              'institution': institution.trim(),
              'course': course.trim(),
              'document_path': path,
            })
            .eq('user_id', userId)
            .eq('status', 'pending');
        return null;
      }
      debugPrint('Erro ao registrar comprovante: $e');
      return 'Não foi possível registrar o comprovante. Tente de novo.';
    } catch (e) {
      debugPrint('Erro ao registrar comprovante: $e');
      return 'Não foi possível registrar o comprovante. Tente de novo.';
    }
  }
}
