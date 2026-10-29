import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_model.dart';
import '../../infra/models/user_model.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/repositories/user_repository.dart';
import '../../shared/enums/view_mode.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';

class ProfessionalsController extends GetxController with LoaderManagerMixin {
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final UserRepository _userRepository = UserRepository();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allProfessionals = [];
  List<Map<String, dynamic>> filteredProfessionals = [];
  bool showPendingOnly = false;
  ViewMode viewMode = ViewMode.list;

  // Paginação
  static const int itemsPerPage = 15;
  int _currentPage = 1;
  int _totalProfessionals = 0;
  int _totalPages = 0;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalProfessionals => _totalProfessionals;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < _totalPages;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() => filterProfessionals());
    loadProfessionals();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Carrega os profissionais da página atual
  Future<void> loadProfessionals() async {
    changeLoading(true);

    // showPendingOnly=false → pending+approved, ordem DESC (pending 'p' antes de approved 'a')
    // showPendingOnly=true  → pending+rejected, ordem ASC  (pending 'p' antes de rejected 'r')
    final statuses =
        showPendingOnly ? ['pending', 'rejected'] : ['pending', 'approved'];
    final ascending = showPendingOnly;

    // Buscar total de profissionais com o mesmo filtro da query
    final countResponse = await _professionalRepository
        .countAllProfessionals(statuses: statuses);
    if (countResponse.success) {
      _totalProfessionals = countResponse.data ?? 0;
      _totalPages = (_totalProfessionals / itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    }

    // Calcular offset baseado na página atual
    final offset = (_currentPage - 1) * itemsPerPage;

    final professionalsResponse = await _professionalRepository
        .getProfessionalsPaginated(
          offset: offset,
          limit: itemsPerPage,
          statuses: statuses,
          ascending: ascending,
        );

    // Carregar dados do usuário para cada profissional
    final professionalsWithUsers = <Map<String, dynamic>>[];

    for (final prof in professionalsResponse.data ?? []) {
      final userResponse = await _userRepository.getUserById(prof.userId);
      if (userResponse.data != null) {
        professionalsWithUsers.add({
          'professional': prof,
          'user': userResponse.data,
        });
      }
    }

    allProfessionals = professionalsWithUsers;
    filterProfessionals();

    changeLoading(false);
    update();
  }

  /// Vai para a página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    _currentPage--;
    await loadProfessionals();
  }

  /// Vai para a próxima página
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    _currentPage++;
    await loadProfessionals();
  }

  /// Vai para uma página específica
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    await loadProfessionals();
  }

  void filterProfessionals() {
    final searchQuery = searchController.text.toLowerCase();

    filteredProfessionals = allProfessionals.where((item) {
      final user = item['user'];
      final professional = item['professional'] as ProfessionalModel;

      // Filtro de status pending e rejected
      if (showPendingOnly) {
        // Quando checkbox ativo: exibir apenas pendentes e rejeitados
        if (professional.validationStatus != ValidationStatus.pending &&
            professional.validationStatus != ValidationStatus.rejected) {
          return false;
        }
      } else {
        // Quando checkbox desmarcado: excluir rejeitados, mostrar apenas aprovados e pendentes
        if (professional.validationStatus == ValidationStatus.rejected) {
          return false;
        }
      }

      // Filtro de busca
      if (searchQuery.isNotEmpty) {
        return user.fullName.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery);
      }

      return true;
    }).toList();

    update();
  }

  void togglePendingFilter() {
    showPendingOnly = !showPendingOnly;
    _currentPage = 1;
    loadProfessionals();
  }

  Future<void> toggleUserStatus(String userId, UserStatus currentStatus) async {
    final newStatus = currentStatus == UserStatus.active
        ? UserStatus.deactivated
        : UserStatus.active;

    final response = await _userRepository.updateUserStatus(userId, newStatus);

    if (response.success) {
      // Atualiza apenas o item modificado em vez de recarregar toda a lista
      _updateUserStatusLocally(userId, newStatus);
      AppSnackbar.to.success(
        'Status do usuário alterado para ${newStatus.displayName.toLowerCase()}',
      );
    } else {
      AppSnackbar.to.error('Erro ao atualizar status');
    }
  }

  /// Atualiza o status do usuário localmente sem recarregar toda a lista
  void _updateUserStatusLocally(String userId, UserStatus newStatus) {
    // Atualiza em allProfessionals
    for (var i = 0; i < allProfessionals.length; i++) {
      final user = allProfessionals[i]['user'] as UserModel;
      if (user.id == userId) {
        allProfessionals[i]['user'] = user.copyWith(status: newStatus);
        break;
      }
    }
    // Atualiza em filteredProfessionals
    for (var i = 0; i < filteredProfessionals.length; i++) {
      final user = filteredProfessionals[i]['user'] as UserModel;
      if (user.id == userId) {
        filteredProfessionals[i]['user'] = user.copyWith(status: newStatus);
        break;
      }
    }
    update();
  }

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    update();
  }
}
