import 'package:get/get.dart';
import '../../infra/models/user_model.dart';
import '../../infra/repositories/user_repository.dart';
import '../../shared/enums/view_mode.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';

class UsersController extends GetxController with LoaderManagerMixin {
  final UserRepository _repository = UserRepository();

  List<Map<String, dynamic>> allUsersWithSubs = [];
  List<Map<String, dynamic>> filteredUsersWithSubs = [];
  String searchQuery = '';
  ViewMode viewMode = ViewMode.list;
  bool filterOnlyWithPlan = false;

  // Paginação
  static const int itemsPerPage = 15;
  int _currentPage = 1;
  int _totalUsers = 0;
  int _totalPages = 0;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalUsers => _totalUsers;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < _totalPages;

  // Para compatibilidade com a UI existente
  List<UserModel> get filteredUsers =>
      filteredUsersWithSubs.map((e) => e['user'] as UserModel).toList();

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  /// Carrega os usuários da página atual
  Future<void> loadUsers() async {
    changeLoading(true);

    // Buscar total de usuários
    final countResponse = await _repository.countUsersByRole(UserRole.user);
    if (countResponse.success) {
      _totalUsers = countResponse.data ?? 0;
      _totalPages = (_totalUsers / itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    }

    // Calcular offset baseado na página atual
    final offset = (_currentPage - 1) * itemsPerPage;

    final response = await _repository.getUsersWithSubscriptionsPaginated(
      offset: offset,
      limit: itemsPerPage,
    );

    if (response.success) {
      // Filtrar apenas usuários do tipo "user"
      final userTypeUsers = (response.data ?? []).where((item) {
        final user = item['user'] as UserModel;
        return user.role == UserRole.user;
      }).toList();

      allUsersWithSubs = userTypeUsers;
      applyFilters();
    } else {
      AppSnackbar.to.error('Falha ao carregar usuários');
    }

    changeLoading(false);
    update();
  }

  /// Vai para a página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    _currentPage--;
    await loadUsers();
  }

  /// Vai para a próxima página
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    _currentPage++;
    await loadUsers();
  }

  /// Vai para uma página específica
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    await loadUsers();
  }

  void filterUsers(String query) {
    final newQuery = query.toLowerCase();
    if (newQuery != searchQuery) {
      searchQuery = newQuery;
      _currentPage = 1; // Voltar para primeira página ao filtrar
      // Se a busca mudou significativamente, recarregar dados
      if (searchQuery.isEmpty || searchQuery.length >= 3) {
        loadUsers();
      } else {
        applyFilters();
        update();
      }
    } else {
      applyFilters();
      update();
    }
  }

  void togglePlanFilter() {
    filterOnlyWithPlan = !filterOnlyWithPlan;
    _currentPage = 1; // Voltar para primeira página ao filtrar
    // Recarregar dados para garantir que temos dados atualizados
    loadUsers();
  }

  void applyFilters() {
    var filtered = allUsersWithSubs;

    // Filtro de busca por nome/email
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final user = item['user'] as UserModel;
        return user.fullName.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Filtro de usuários com plano
    if (filterOnlyWithPlan) {
      filtered = filtered.where((item) {
        return item['subscription'] != null;
      }).toList();
    }

    filteredUsersWithSubs = filtered;
  }

  String? getUserPlanName(UserModel user) {
    final item = filteredUsersWithSubs.firstWhere(
      (item) => (item['user'] as UserModel).id == user.id,
      orElse: () => {},
    );

    if (item.isEmpty || item['subscription'] == null) return null;

    final plan = item['subscription']['tb_subscription_plans'];
    return plan != null ? plan['reason'] as String? : null;
  }

  Map<String, dynamic>? getUserSubscription(UserModel user) {
    final item = filteredUsersWithSubs.firstWhere(
      (item) => (item['user'] as UserModel).id == user.id,
      orElse: () => {},
    );

    return item.isEmpty ? null : item['subscription'];
  }

  Future<void> toggleUserStatus(UserModel user) async {
    final newStatus = user.status == UserStatus.active
        ? UserStatus.deactivated
        : UserStatus.active;

    final response = await _repository.updateUserStatus(user.id!, newStatus);

    if (response.success && response.data == true) {
      // Atualiza apenas o item modificado em vez de recarregar toda a lista
      _updateUserStatusLocally(user.id!, newStatus);
      AppSnackbar.to.success(
        'Status do usuário alterado para ${newStatus.displayName.toLowerCase()}',
      );
    } else {
      AppSnackbar.to.error('Falha ao atualizar status do usuário');
    }
  }

  /// Atualiza o status do usuário localmente sem recarregar toda a lista
  void _updateUserStatusLocally(String userId, UserStatus newStatus) {
    // Atualiza em allUsersWithSubs
    for (var i = 0; i < allUsersWithSubs.length; i++) {
      final user = allUsersWithSubs[i]['user'] as UserModel;
      if (user.id == userId) {
        allUsersWithSubs[i]['user'] = user.copyWith(status: newStatus);
        break;
      }
    }
    // Atualiza em filteredUsersWithSubs
    for (var i = 0; i < filteredUsersWithSubs.length; i++) {
      final user = filteredUsersWithSubs[i]['user'] as UserModel;
      if (user.id == userId) {
        filteredUsersWithSubs[i]['user'] = user.copyWith(status: newStatus);
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
