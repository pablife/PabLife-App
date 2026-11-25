import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/utils/birth_date.dart';
import '../models/gender.dart';

typedef UserPersonalData = ({DateTime? birthDate, Gender? gender});

/// Data de nascimento e gênero. Só a própria pessoa (e o administrador) leem.
class UserPersonalDataRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Os dados guardados, ou null se não deu para ler (assim a tela não
  /// confunde "não carregou" com "não preencheu").
  Future<UserPersonalData?> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('tb_user_personal_data')
          .select('birth_date, gender')
          .eq('user_id', userId)
          .maybeSingle();
      return (
        birthDate: DateTime.tryParse(row?['birth_date'] as String? ?? ''),
        gender: Gender.fromValue(row?['gender'] as String?),
      );
    } catch (e) {
      debugPrint('Dados pessoais indisponíveis: $e');
      return null;
    }
  }

  Future<bool> save({DateTime? birthDate, Gender? gender}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client.from('tb_user_personal_data').upsert({
        'user_id': userId,
        'birth_date': birthDate == null
            ? null
            : BirthDate.toDatabase(birthDate),
        'gender': gender?.value,
      });
      return true;
    } catch (e) {
      debugPrint('Não foi possível guardar os dados pessoais: $e');
      return false;
    }
  }

  /// Logo depois de criar a conta: tenta de novo uma vez se a rede falhar.
  Future<bool> saveAfterSignUp({DateTime? birthDate, Gender? gender}) async {
    if (birthDate == null && gender == null) return true;
    return await save(birthDate: birthDate, gender: gender) ||
        await save(birthDate: birthDate, gender: gender);
  }
}
