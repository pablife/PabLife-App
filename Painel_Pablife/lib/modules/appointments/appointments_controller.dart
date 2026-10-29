import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../infra/models/appointment_model.dart';
import '../../infra/models/professional_model.dart';
import '../../infra/models/user_model.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/repositories/user_repository.dart';
import '../../shared/enums/view_mode.dart';
import '../../shared/utils/app_snackbar.dart';

class AppointmentsController extends GetxController {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final UserRepository _userRepository = UserRepository();

  // State
  bool isLoading = true;
  List<AppointmentModel> appointments = [];
  List<AppointmentModel> filtered = [];
  List<AppointmentModel> paginatedFiltered = [];

  // Maps auxiliares para nomes
  final Map<String, ProfessionalModel> professionalsMap = {};
  final Map<String, UserModel> usersMap = {};

  // Filtros
  String? professionalFilterId;
  DateTimeRange? dateRange;
  final clientSearchController = TextEditingController();

  // View Mode
  ViewMode viewMode = ViewMode.list;

  // Paginação
  static const int itemsPerPage = 15;
  int _currentPage = 1;
  int _totalPages = 0;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < _totalPages;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    clientSearchController.addListener(() {
      _currentPage = 1; // Voltar para primeira página ao buscar
      applyFilters();
    });
  }

  @override
  void onClose() {
    clientSearchController.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    isLoading = true;
    update();

    final appointmentsResponse = await _appointmentRepository
        .getAllAppointments();

    if (!appointmentsResponse.success) {
      AppSnackbar.to.error('Falha ao carregar agendamentos');
      isLoading = false;
      update();
      return;
    }

    // Carregar usuários e profissionais para mapear nomes
    final prosResponse = await _professionalRepository.getAllProfessionals();
    final usersResponse = await _userRepository.getAllUsers();

    professionalsMap.clear();
    for (final p in prosResponse.data ?? []) {
      professionalsMap[p.id] = p;
    }

    professionalsMap.clear();
    for (final p in prosResponse.data ?? []) {
      professionalsMap[p.id] = p;
    }

    usersMap.clear();
    for (final u in usersResponse.data ?? []) {
      usersMap[u.id!] = u;
    }

    appointments = appointmentsResponse.data ?? [];
    filtered = appointmentsResponse.data ?? [];
    _currentPage = 1;
    _updatePagination();
    isLoading = false;
    update();
  }

  void applyFilters() {
    final query = clientSearchController.text.toLowerCase();

    filtered =
        appointments.where((a) {
          // Profissional
          if (professionalFilterId != null &&
              professionalFilterId!.isNotEmpty &&
              a.professionalId != professionalFilterId) {
            return false;
          }

          // Período
          if (dateRange != null) {
            final due = a.startOfScheduledWindow;
            final start = DateTime(
              dateRange!.start.year,
              dateRange!.start.month,
              dateRange!.start.day,
            );
            final end = DateTime(
              dateRange!.end.year,
              dateRange!.end.month,
              dateRange!.end.day,
              23,
              59,
              59,
            );
            if (due.isBefore(start) || due.isAfter(end)) return false;
          }

          // Cliente (nome/email)
          if (query.isNotEmpty) {
            final user = usersMap[a.scheduledBy];
            final matches =
                user != null &&
                ((user.fullName.toLowerCase().contains(query)) ||
                    (user.email.toLowerCase().contains(query)));
            if (!matches) return false;
          }

          return true;
        }).toList()..sort(
          (b, c) =>
              c.startOfScheduledWindow.compareTo(b.startOfScheduledWindow),
        );

    // Calcular paginação dos dados filtrados
    _updatePagination();
    update();
  }

  void _updatePagination() {
    _totalPages = (filtered.length / itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    
    // Ajustar página atual se necessário
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }

    // Aplicar paginação nos dados filtrados
    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);
    paginatedFiltered = filtered.sublist(
      startIndex.clamp(0, filtered.length),
      endIndex,
    );
  }

  void setProfessionalFilter(String? id) {
    professionalFilterId = id;
    _currentPage = 1; // Voltar para primeira página ao filtrar
    applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    dateRange = range;
    _currentPage = 1; // Voltar para primeira página ao filtrar
    applyFilters();
  }

  void clearFilters() {
    professionalFilterId = null;
    dateRange = null;
    clientSearchController.clear();
    _currentPage = 1; // Voltar para primeira página ao limpar filtros
    applyFilters();
  }

  /// Vai para a página anterior
  void goToPreviousPage() {
    if (!hasPreviousPage) return;
    _currentPage--;
    _updatePagination();
    update();
  }

  /// Vai para a próxima página
  void goToNextPage() {
    if (!hasNextPage) return;
    _currentPage++;
    _updatePagination();
    update();
  }

  /// Vai para uma página específica
  void goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    _updatePagination();
    update();
  }

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  ProfessionalModel? getProfessional(String id) => professionalsMap[id];

  UserModel? getUser(String id) => usersMap[id];

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    update();
  }
}
