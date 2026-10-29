import 'package:painel_pablife/infra/models/mentorship_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';

class MentorshipRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  /// Buscar todas as Mentorship
  FStrautilsResponse<List<MentorshipModel>> getAllMentorship() async {
    return tryThis<List<MentorshipModel>>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .select('''
            *,
            category:tb_mentoring_categories(name)
          ''')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);

        final list = (response as List).map((item) {
          final data = Map<String, dynamic>.from(item);
          if (data['category'] != null && data['category'] is Map) {
            data['category_name'] = data['category']['name'];
          }
          return MentorshipModel.fromMap(data);
        }).toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAllMentorship(),
      action: 'buscar mentorias',
    );
  }

  /// Buscar mentorias com paginação
  /// [offset] - posição inicial
  /// [limit] - quantidade de itens a carregar
  FStrautilsResponse<List<MentorshipModel>> getMentorshipsPaginated({
    required int offset,
    int limit = 15,
  }) async {
    return tryThis<List<MentorshipModel>>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .select('''
            *,
            category:tb_mentoring_categories(name)
          ''')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final list = (response as List).map((item) {
          final data = Map<String, dynamic>.from(item);
          if (data['category'] != null && data['category'] is Map) {
            data['category_name'] = data['category']['name'];
          }
          return MentorshipModel.fromMap(data);
        }).toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getMentorshipsPaginated(offset: offset, limit: limit),
      action: 'buscar mentorias paginadas',
    );
  }

  /// Buscar mentorship por ID
  FStrautilsResponse<MentorshipModel?> getMentorshipById(String id) async {
    return tryThis<MentorshipModel?>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .select('''
            *,
            category:tb_mentoring_categories(name)
          ''')
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          final data = Map<String, dynamic>.from(response);
          if (data['category'] != null && data['category'] is Map) {
            data['category_name'] = data['category']['name'];
          }
          return StrautilsResponse.success(MentorshipModel.fromMap(data));
        }
        return StrautilsResponse.success(null);
      },
      tryAgain: () => getMentorshipById(id),
      action: 'buscar mentoria por ID',
    );
  }

  /// Criar nova mentorship
  FStrautilsResponse<MentorshipModel?> createMentorship(
    MentorshipModel mentorship,
  ) async {
    return tryThis<MentorshipModel?>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .insert(mentorship.toMap())
            .select()
            .single();

        return StrautilsResponse.success(MentorshipModel.fromMap(response));
      },
      tryAgain: () => createMentorship(mentorship),
      action: 'criar mentoria',
    );
  }

  /// Criar nova mentorship a partir de Map
  FStrautilsResponse<MentorshipModel?> createMentorshipFromMap(
    Map<String, dynamic> data,
  ) async {
    return tryThis<MentorshipModel?>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .insert(data)
            .select()
            .single();

        return StrautilsResponse.success(MentorshipModel.fromMap(response));
      },
      tryAgain: () => createMentorshipFromMap(data),
      action: 'criar mentoria a partir de map',
    );
  }

  /// Atualizar mentorship
  FStrautilsResponse<bool> updateMentorship(
    String id,
    Map<String, dynamic> data,
  ) async {
    return tryThis<bool>(
      () async {
        data['updated_at'] = DateTime.now().toIso8601String();
        await _client.from('tb_mentorships').update(data).eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => updateMentorship(id, data),
      action: 'atualizar mentoria',
    );
  }

  /// Deletar mentorship (soft delete)
  FStrautilsResponse<bool> deleteMentorship(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_mentorships')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => deleteMentorship(id),
      action: 'deletar mentoria',
    );
  }

  /// Ativar mentorship
  FStrautilsResponse<bool> activateMentorship(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_mentorships')
            .update({
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => activateMentorship(id),
      action: 'ativar mentoria',
    );
  }

  /// Desativar mentorship
  FStrautilsResponse<bool> deactivateMentorship(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_mentorships')
            .update({
              'is_active': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => deactivateMentorship(id),
      action: 'desativar mentoria',
    );
  }

  /// Buscar categorias
  FStrautilsResponse<List<MentorshipCategoryModel>> getCategories() async {
    return tryThis<List<MentorshipCategoryModel>>(
      () async {
        final response = await _client
            .from('tb_mentoring_categories')
            .select()
            .isFilter('deleted_at', null)
            .order('name', ascending: true);

        final list = (response as List)
            .map((item) => MentorshipCategoryModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getCategories(),
      action: 'buscar categorias',
    );
  }

  /// Criar categoria
  FStrautilsResponse<MentorshipCategoryModel?> createCategory(
    String name,
  ) async {
    return tryThis<MentorshipCategoryModel?>(
      () async {
        final response = await _client
            .from('tb_mentoring_categories')
            .insert({
              'name': name,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return StrautilsResponse.success(
          MentorshipCategoryModel.fromMap(response),
        );
      },
      tryAgain: () => createCategory(name),
      action: 'criar categoria',
    );
  }

  /// Contar Mentorship
  FStrautilsResponse<int> getTotalMentorship() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_mentorships')
            .select('id')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getTotalMentorship(),
      action: 'contar mentorias',
    );
  }

  /// Listar módulos por mentorship
  FStrautilsResponse<List<MentorshipModuleModel>> getModulesByMentorship(
    String mentorshipId,
  ) async {
    return tryThis<List<MentorshipModuleModel>>(
      () async {
        final response = await _client
            .from('tb_mentoring_modules')
            .select()
            .eq('mentoring_id', mentorshipId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);

        final list = (response as List)
            .map(
              (e) =>
                  MentorshipModuleModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getModulesByMentorship(mentorshipId),
      action: 'buscar módulos da mentoria',
    );
  }

  /// Listar lições por módulo
  FStrautilsResponse<List<ModuleLessonModel>> getLessonsByModule(
    String moduleId,
  ) async {
    return tryThis<List<ModuleLessonModel>>(
      () async {
        final response = await _client
            .from('tb_module_lessons')
            .select()
            .eq('mentoring_module_id', moduleId)
            .isFilter('deleted_at', null)
            .order('lesson_number', ascending: true);

        final list = (response as List)
            .map((e) => ModuleLessonModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getLessonsByModule(moduleId),
      action: 'buscar lições do módulo',
    );
  }

  /// Criar módulo
  FStrautilsResponse<MentorshipModuleModel?> createModule({
    required String mentoringId,
    required String name,
  }) async {
    return tryThis<MentorshipModuleModel?>(
      () async {
        final response = await _client
            .from('tb_mentoring_modules')
            .insert({
              'mentoring_id': mentoringId,
              'name': name,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return StrautilsResponse.success(
          MentorshipModuleModel.fromMap(response),
        );
      },
      tryAgain: () => createModule(mentoringId: mentoringId, name: name),
      action: 'criar módulo',
    );
  }

  /// Atualizar módulo
  FStrautilsResponse<bool> updateModule(String id, String name) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_mentoring_modules')
            .update({
              'name': name,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => updateModule(id, name),
      action: 'atualizar módulo',
    );
  }

  /// Deletar módulo
  FStrautilsResponse<bool> deleteModule(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_mentoring_modules')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => deleteModule(id),
      action: 'deletar módulo',
    );
  }

  /// Criar aula
  FStrautilsResponse<ModuleLessonModel?> createLesson({
    required String mentoringModuleId,
    required int lessonNumber,
    required String title,
    required String videoUrl,
  }) async {
    return tryThis<ModuleLessonModel?>(
      () async {
        final response = await _client
            .from('tb_module_lessons')
            .insert({
              'mentoring_module_id': mentoringModuleId,
              'lesson_number': lessonNumber,
              'title': title,
              'video_url': videoUrl,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return StrautilsResponse.success(ModuleLessonModel.fromMap(response));
      },
      tryAgain: () => createLesson(
        mentoringModuleId: mentoringModuleId,
        lessonNumber: lessonNumber,
        title: title,
        videoUrl: videoUrl,
      ),
      action: 'criar aula',
    );
  }

  /// Atualizar aula
  FStrautilsResponse<bool> updateLesson({
    required String id,
    required int lessonNumber,
    required String title,
    required String videoUrl,
  }) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_module_lessons')
            .update({
              'lesson_number': lessonNumber,
              'title': title,
              'video_url': videoUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => updateLesson(
        id: id,
        lessonNumber: lessonNumber,
        title: title,
        videoUrl: videoUrl,
      ),
      action: 'atualizar aula',
    );
  }

  /// Deletar aula
  FStrautilsResponse<bool> deleteLesson(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_module_lessons')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => deleteLesson(id),
      action: 'deletar aula',
    );
  }
}
