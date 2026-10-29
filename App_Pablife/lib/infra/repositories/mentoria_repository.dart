import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mentoria_category_model.dart';
import '../models/mentoria_model.dart';
import '../models/mentoria_module_model.dart';
import '../models/mentoria_video_model.dart';

class MentoriaRepository extends StrautilsTryThis {
  MentoriaRepository();

  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<MentoriaCategoryModel>> getCategories() {
    return tryThis(() async {
      final response = await _client
          .from('tb_mentoring_categories')
          .select('id, name')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final categories = (response as List<dynamic>)
          .map(
            (row) => MentoriaCategoryModel.fromMap(row as Map<String, dynamic>),
          )
          .toList();

      return StrautilsResponse.success(categories);
    }, action: 'buscar categorias de mentorias.');
  }

  FStrautilsResponse<List<MentoriaModel>> getAll({
    String? categoryId,
    String? searchTerm,
  }) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      final favoriteIds = await _getFavoriteMentorshipIds(userId);

      final mentorships = await _fetchAllMentorshipRows();

      final models = mentorships
          .map((row) => _mapMentoria(row, favoriteIds))
          .toList();

      final filteredModels = _applyLocalFilters(
        models,
        categoryId: categoryId,
        searchTerm: searchTerm,
      );

      return StrautilsResponse.success(filteredModels);
    }, action: 'buscar todas as mentorias.');
  }

  FStrautilsResponse<List<MentoriaModel>> getByCategory(String categoryId) {
    return tryThis(() async {
      if (categoryId.isEmpty) {
        return await getAll();
      }

      final response = await getAll(categoryId: categoryId);
      if (!response.success || response.data == null) {
        return StrautilsResponse.success(<MentoriaModel>[]);
      }

      return StrautilsResponse.success(response.data!);
    }, action: 'buscar mentorias por categoria.');
  }

  FStrautilsResponse<List<MentoriaModel>> getSaved() {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final favoriteIds = await _getFavoriteMentorshipIds(userId);
      if (favoriteIds.isEmpty) {
        return StrautilsResponse.success(<MentoriaModel>[]);
      }

      final mentorships = await _fetchAllMentorshipRows();

      final models = mentorships
          .map((row) => _mapMentoria(row, favoriteIds))
          .toList();

      final filteredModels = models
          .where((mentoria) => favoriteIds.contains(mentoria.id))
          .toList();

      return StrautilsResponse.success(filteredModels);
    }, action: 'buscar mentorias salvas.');
  }

  FStrautilsResponse<List<MentoriaModel>> search(
    String query, {
    String? categoryId,
  }) {
    return tryThis(() async {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return await getAll(categoryId: categoryId);
      }

      final response = await getAll(
        categoryId: categoryId,
        searchTerm: trimmedQuery,
      );
      if (!response.success || response.data == null) {
        return StrautilsResponse.success(<MentoriaModel>[]);
      }

      return StrautilsResponse.success(response.data!);
    }, action: 'buscar mentorias por termo.');
  }

  FStrautilsResponse<bool> setFavoriteStatus(
    String mentoriaId,
    bool shouldFavorite,
  ) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final existing = await _client
          .from('tb_favorite_mentorships')
          .select('id')
          .eq('user_id', userId)
          .eq('mentorship_id', mentoriaId)
          .maybeSingle();

      if (shouldFavorite) {
        if (existing == null) {
          await _client.from('tb_favorite_mentorships').insert({
            'user_id': userId,
            'mentorship_id': mentoriaId,
          });
        }
        return StrautilsResponse.success(true);
      } else {
        if (existing != null) {
          await _client
              .from('tb_favorite_mentorships')
              .delete()
              .eq('id', existing['id'])
              .eq('user_id', userId);
        }
        return StrautilsResponse.success(false);
      }
    }, action: 'definir salvamento de mentoria.');
  }

  FStrautilsResponse<List<MentoriaModuleModel>> getModules(String mentoriaId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_mentoring_modules')
          .select('id, mentoring_id, name, created_at, updated_at')
          .eq('mentoring_id', mentoriaId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      final modules = (response as List<dynamic>)
          .map(
            (row) => MentoriaModuleModel.fromMap(row as Map<String, dynamic>),
          )
          .toList();

      final coloredModules = modules.asMap().entries.map((entry) {
        final index = entry.key;
        final fallbackColor =
            _moduleFallbackColors[index % _moduleFallbackColors.length];
        return entry.value.copyWith(colorHex: fallbackColor);
      }).toList();

      return StrautilsResponse.success(coloredModules);
    }, action: 'buscar módulos da mentoria.');
  }

  FStrautilsResponse<List<MentoriaVideoModel>> getVideos(String mentoriaId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_module_lessons')
          .select(
            'id, mentoring_module_id, lesson_number, title, video_url, created_at, updated_at, module:tb_mentoring_modules!inner(mentoring_id)',
          )
          .eq('module.mentoring_id', mentoriaId)
          .isFilter('deleted_at', null)
          .order('mentoring_module_id', ascending: true)
          .order('lesson_number', ascending: true);

      final videos = (response as List<dynamic>)
          .map((row) => MentoriaVideoModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return StrautilsResponse.success(videos);
    }, action: 'buscar vídeos da mentoria.');
  }

  FStrautilsResponse<String?> getLastWatchedVideo(String mentoriaId) {
    return tryThis(() async {
      return StrautilsResponse.success(null);
    }, action: 'buscar último vídeo assistido.');
  }

  Future<List<Map<String, dynamic>>> _fetchAllMentorshipRows() async {
    final response = await _client
        .from('tb_mentorships')
        .select(
          'id, title, author, duration, description, created_at, updated_at, category_id, category:tb_mentoring_categories(id, name), image_url',
        )
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  List<MentoriaModel> _applyLocalFilters(
    List<MentoriaModel> mentorias, {
    String? categoryId,
    String? searchTerm,
  }) {
    Iterable<MentoriaModel> filtered = mentorias;

    if (categoryId != null && categoryId.isNotEmpty) {
      filtered = filtered.where(
        (mentoria) => mentoria.categoryId == categoryId,
      );
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final normalized = searchTerm.toLowerCase();
      filtered = filtered.where(
        (mentoria) =>
            mentoria.title.toLowerCase().contains(normalized) ||
            mentoria.description.toLowerCase().contains(normalized) ||
            mentoria.author.toLowerCase().contains(normalized),
      );
    }

    return filtered.toList();
  }

  MentoriaModel _mapMentoria(
    Map<String, dynamic> row,
    Set<String> favoriteIds,
  ) {
    final model = MentoriaModel.fromMap(row);
    final isSaved = favoriteIds.contains(model.id);

    return model.copyWith(
      isSaved: isSaved,
      imageUrl:
          (row['image_url'] ?? row['imageUrl'])?.toString() ?? model.imageUrl,
    );
  }

  Future<Set<String>> _getFavoriteMentorshipIds(String? userId) async {
    if (userId == null) {
      return <String>{};
    }

    final response = await _client
        .from('tb_favorite_mentorships')
        .select('mentorship_id')
        .eq('user_id', userId);

    final ids = (response as List<dynamic>)
        .map(
          (row) => (row as Map<String, dynamic>)['mentorship_id']?.toString(),
        )
        .whereType<String>()
        .toSet();

    return ids;
  }
}

const List<String> _moduleFallbackColors = [
  '0xFF00343C',
  '0xFF22717D',
  '0xFF0C8DA1',
  '0xFFAEBEEC',
];
