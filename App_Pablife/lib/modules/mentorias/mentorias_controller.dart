import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/mentoria_category_model.dart';
import '../../infra/models/mentoria_model.dart';
import '../../infra/repositories/mentoria_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/dialogs/premium_lock_dialog.dart';
import 'mentoria_view_page.dart';

class MentoriasController extends GetxController with LoaderManagerMixin {
  final MentoriaRepository _repository = MentoriaRepository();
  final AuthService _authService = AuthService.instance;

  MentoriasController();

  /// Verifica se o usuário pode acessar as mentorias
  bool get canAccessMentorias => _authService.canAccessMentorias;

  /// Verifica se o usuário está em trial
  bool get isInTrial => _authService.isInTrial;

  /// Retorna dias restantes do trial
  int? get trialDaysRemaining => _authService.trialDaysRemaining;

  final TextEditingController searchController = TextEditingController();

  List<MentoriaModel> mentorias = [];
  List<MentoriaModel> filteredMentorias = [];
  List<MentoriaModel> savedMentorias = [];
  List<MentoriaCategoryModel> categoryModels = [];
  final Map<String, String> _categoryNameToId = {};
  final Map<String, Timer> _favoriteTimers = {};
  final Map<String, bool> _pendingFavoriteStates = {};
  final Duration _favoriteDebounceDuration = const Duration(milliseconds: 600);
  List<String> categories = ['Todos'];
  String selectedCategory = 'Todos';
  String? selectedCategoryId;
  bool showOnlySaved = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onReady() {
    super.onReady();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    changeLoading(true);

    await _loadCategories();
    await loadMentorias();

    changeLoading(false);
  }

  Future<void> _loadCategories() async {
    final response = await _repository.getCategories();
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      categoryModels = response.data ?? [];
      categories = categoryModels.map((category) => category.name).toList();
      if (categories.length > 1) {
        categories.insert(0, 'Todos');
      }
      selectedCategory = categories.first;

      _categoryNameToId
        ..clear()
        ..addEntries(
          categoryModels.map(
            (category) =>
                MapEntry(_normalizeCategoryName(category.name), category.id),
          ),
        );

      selectedCategoryId = null;
    }
    update();
  }

  @override
  void onClose() {
    for (final timer in _favoriteTimers.values) {
      timer.cancel();
    }
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadMentorias() async {
    final response = await _repository.getAll(categoryId: selectedCategoryId);
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      mentorias = response.data ?? [];
      _applyFilters();
    }
  }

  Future<void> changeCategory(String category) async {
    if (selectedCategory == category) return;

    selectedCategory = category;
    selectedCategoryId = _resolveCategoryIdByName(category);
    showOnlySaved = false;
    update();

    changeLoading(true);

    final response = selectedCategoryId == null
        ? await _repository.getAll()
        : await _repository.getByCategory(selectedCategoryId!);
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      mentorias = response.data ?? [];
      _applyFilters();
    }

    changeLoading(false);
  }

  Future<void> toggleSavedFilter() async {
    showOnlySaved = !showOnlySaved;
    update();

    if (showOnlySaved) {
      changeLoading(true);

      final response = await _repository.getSaved();
      if (!response.success) {
        AppSnackbar.to.show(response.message);
        showOnlySaved = false;
        changeLoading(false);
        update();
        _applyFilters();
      } else {
        final savedItems = response.data ?? [];
        final savedIds = savedItems.map((m) => m.id).toSet();

        mentorias = mentorias
            .map((ment) => ment.copyWith(isSaved: savedIds.contains(ment.id)))
            .toList();

        savedMentorias = savedItems;
        filteredMentorias = List<MentoriaModel>.from(savedMentorias);
        changeLoading(false);
        update();
      }
    } else {
      _applyFilters();
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> searchMentorias(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await loadMentorias();
      return;
    }

    if (showOnlySaved) {
      _applyFilters();
      return;
    }

    changeLoading(true);

    final response = await _repository.search(
      trimmedQuery,
      categoryId: selectedCategoryId,
    );
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      mentorias = response.data ?? [];
      _applyFilters();
    }

    changeLoading(false);
  }

  void _applyFilters() {
    final baseList = showOnlySaved ? savedMentorias : mentorias;
    filteredMentorias = List<MentoriaModel>.from(baseList);

    final searchText = searchController.text.trim().toLowerCase();

    if (searchText.isNotEmpty) {
      filteredMentorias = filteredMentorias
          .where(
            (m) =>
                m.title.toLowerCase().contains(searchText) ||
                m.description.toLowerCase().contains(searchText) ||
                m.author.toLowerCase().contains(searchText),
          )
          .toList();
    }

    if (showOnlySaved) {
      filteredMentorias = filteredMentorias.where((m) => m.isSaved).toList();
    }

    update();
  }

  Future<void> toggleSaveMentoria(MentoriaModel mentoria) async {
    final desiredState = !mentoria.isSaved;
    _setMentoriaSavedState(mentoria.id, desiredState);
    _pendingFavoriteStates[mentoria.id] = desiredState;
    _favoriteTimers[mentoria.id]?.cancel();
    _favoriteTimers[mentoria.id] = Timer(_favoriteDebounceDuration, () async {
      final targetState = _pendingFavoriteStates[mentoria.id];
      if (targetState == null) return;

      final response = await _repository.setFavoriteStatus(
        mentoria.id,
        targetState,
      );

      if (!response.success) {
        AppSnackbar.to.show(response.message);
        _setMentoriaSavedState(mentoria.id, !targetState);
      } else {
        final serverState = response.data ?? targetState;
        _setMentoriaSavedState(mentoria.id, serverState);
      }

      _pendingFavoriteStates.remove(mentoria.id);
      _favoriteTimers.remove(mentoria.id);
      _applyFilters();
    });

    _applyFilters();
  }

  Future<void> openMentoria(MentoriaModel mentoria) async {
    if (mentoria.isLocked) {
      AppSnackbar.to.show('Esta mentoria está bloqueada');
      return;
    }

    // Verificar se o usuário tem acesso às mentorias
    await _authService.reloadUserAccessInfo();
    if (!canAccessMentorias) {
      if (isInTrial) {
        Get.dialog(
          PremiumLockDialog(
            message:
                'As mentorias não estão disponíveis durante o período de trial. '
                'Assine um plano para ter acesso ilimitado!',
            contentType: 'Mentoria',
            contentTitle: mentoria.title,
          ),
        );
      } else {
        Get.dialog(
          PremiumLockDialog(
            message:
                'Você precisa de uma assinatura ativa para acessar as mentorias. '
                'Assine um plano para ter acesso!',
            contentType: 'Mentoria',
            contentTitle: mentoria.title,
          ),
        );
      }
      return;
    }

    Get.toNamed(
      MentoriaViewPage.route,
      arguments: {
        'mentoria': mentoria,
        'onFavoriteChanged': _handleFavoriteFromDetail,
      },
    );
  }

  void openNotifications() {
    Get.toNamed('/notifications');
  }

  String? _resolveCategoryIdByName(String categoryName) {
    if (categoryName == 'Todos') return null;
    final normalized = _normalizeCategoryName(categoryName);
    return _categoryNameToId[normalized];
  }

  String _normalizeCategoryName(String value) {
    return value.trim().toLowerCase();
  }

  void _setMentoriaSavedState(String mentoriaId, bool isSaved) {
    final index = mentorias.indexWhere((m) => m.id == mentoriaId);
    if (index != -1) {
      final updated = mentorias[index].copyWith(isSaved: isSaved);
      mentorias[index] = updated;
    }

    final savedIndex = savedMentorias.indexWhere((m) => m.id == mentoriaId);
    final updatedModel = index != -1 ? mentorias[index] : null;

    if (isSaved) {
      if (savedIndex == -1 && updatedModel != null) {
        savedMentorias.add(updatedModel);
      } else if (savedIndex != -1 && updatedModel != null) {
        savedMentorias[savedIndex] = updatedModel;
      }
    } else {
      if (savedIndex != -1) {
        savedMentorias.removeAt(savedIndex);
      }
    }
  }

  void _handleFavoriteFromDetail(String mentoriaId, bool isSaved) {
    _setMentoriaSavedState(mentoriaId, isSaved);
    _applyFilters();
  }
}
