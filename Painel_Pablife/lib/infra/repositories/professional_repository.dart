import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/professional_model.dart';

class ProfessionalRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  /// Buscar todos os profissionais
  FStrautilsResponse<List<ProfessionalModel>> getAllProfessionals() async {
    return tryThis<List<ProfessionalModel>>(
      () async {
        final response = await _client
            .from('tb_professionals')
            .select('*, user:user_id(full_name)')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((item) => ProfessionalModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAllProfessionals(),
      action: 'buscar profissionais',
    );
  }

  /// Buscar profissionais com paginação (lazy loading)
  /// [offset] - posição inicial
  /// [limit] - quantidade de itens a carregar
  /// [statuses] - filtrar por status específicos (null = todos)
  /// [ascending] - ordenação do validation_status
  FStrautilsResponse<List<ProfessionalModel>> getProfessionalsPaginated({
    required int offset,
    int limit = 15,
    List<String>? statuses,
    bool ascending = true,
  }) async {
    return tryThis<List<ProfessionalModel>>(
      () async {
        var query = _client
            .from('tb_professionals')
            .select()
            .isFilter('deleted_at', null);

        if (statuses != null && statuses.isNotEmpty) {
          query = query.inFilter('validation_status', statuses);
        }

        final response = await query
            .order('validation_status', ascending: ascending)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final list = (response as List)
            .map((item) => ProfessionalModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getProfessionalsPaginated(
          offset: offset, limit: limit, statuses: statuses, ascending: ascending),
      action: 'buscar profissionais paginados',
    );
  }

  /// Conta o total de profissionais (excluindo deletados)
  /// [statuses] - filtrar por status específicos (null = todos)
  FStrautilsResponse<int> countAllProfessionals({List<String>? statuses}) async {
    return tryThis<int>(
      () async {
        var query = _client
            .from('tb_professionals')
            .select('id')
            .isFilter('deleted_at', null);

        if (statuses != null && statuses.isNotEmpty) {
          query = query.inFilter('validation_status', statuses);
        }

        final response = await query.count(CountOption.exact);
        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => countAllProfessionals(statuses: statuses),
      action: 'contar profissionais',
    );
  }

  /// Buscar profissionais pendentes de aprovação
  FStrautilsResponse<List<ProfessionalModel>> getPendingProfessionals() async {
    return tryThis<List<ProfessionalModel>>(
      () async {
        final response = await _client
            .from('tb_professionals')
            .select()
            .eq('validation_status', 'pending')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((item) => ProfessionalModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getPendingProfessionals(),
      action: 'buscar profissionais pendentes',
    );
  }

  /// Buscar profissional por ID
  FStrautilsResponse<ProfessionalModel?> getProfessionalById(String id) async {
    return tryThis<ProfessionalModel?>(
      () async {
        final response = await _client
            .from('tb_professionals')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return StrautilsResponse.success(ProfessionalModel.fromMap(response));
        }
        return StrautilsResponse.success(null);
      },
      tryAgain: () => getProfessionalById(id),
      action: 'buscar profissional por ID',
    );
  }

  /// Atualizar status de validação
  FStrautilsResponse<bool> updateValidationStatus(
    String id,
    ValidationStatus status,
  ) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_professionals')
            .update({
              'validation_status': status.value,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => updateValidationStatus(id, status),
      action: 'atualizar status de validação',
    );
  }

  /// Contar profissionais por status
  FStrautilsResponse<Map<String, int>> countByStatus() async {
    return tryThis<Map<String, int>>(
      () async {
        final pending = await _client
            .from('tb_professionals')
            .select('id')
            .eq('validation_status', 'pending')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        final approved = await _client
            .from('tb_professionals')
            .select('id')
            .eq('validation_status', 'approved')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        return StrautilsResponse.success({
          'pending': pending.count,
          'approved': approved.count,
        });
      },
      tryAgain: () => countByStatus(),
      action: 'contar profissionais por status',
    );
  }

  /// Contar profissionais por tipo (nutritionist, psychologist)
  FStrautilsResponse<Map<String, int>> countByType() async {
    return tryThis<Map<String, int>>(
      () async {
        final nutritionists = await _client
            .from('tb_professionals')
            .select('id')
            .eq('type', 'nutritionist')
            .eq('validation_status', 'approved')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        final psychologists = await _client
            .from('tb_professionals')
            .select('id')
            .eq('type', 'psychologist')
            .eq('validation_status', 'approved')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        return StrautilsResponse.success({
          'nutritionist': nutritionists.count,
          'psychologist': psychologists.count,
        });
      },
      tryAgain: () => countByType(),
      action: 'contar profissionais por tipo',
    );
  }

  /// Buscar profissional com dados do usuário
  FStrautilsResponse<Map<String, dynamic>?> getProfessionalWithUser(
    String professionalId,
  ) async {
    return tryThis<Map<String, dynamic>?>(
      () async {
        final response = await _client
            .from('tb_professionals')
            .select('''
            *,
            tb_users!inner(*)
          ''')
            .eq('id', professionalId)
            .maybeSingle();

        return StrautilsResponse.success(response);
      },
      tryAgain: () => getProfessionalWithUser(professionalId),
      action: 'buscar profissional com usuário',
    );
  }
}
