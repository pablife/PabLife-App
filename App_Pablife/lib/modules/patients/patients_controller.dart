import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../appointment_details/appointment_details_routes.dart';
import '../appointment_details/widgets/reschedule_bottom_sheet.dart';

class PatientsController extends GetxController with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();

  final TextEditingController searchController = TextEditingController();
  final List<String> tabs = ['Ativos', 'Histórico'];

  int currentTab = 0;
  String searchQuery = '';
  List<ProfessionalAppointmentModel> _allAppointments = [];
  String? _professionalId;

  @override
  void onInit() {
    super.onInit();
    _loadProfessional();
  }

  Future<void> _loadProfessional() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final response = await _professionalRepository.getProfessionalByUserId(
      userId,
    );
    if (response.success && response.data != null) {
      _professionalId = response.data!.id;
      await loadAppointments();
    }
  }

  Future<void> loadAppointments() async {
    final professionalId = _professionalId;
    if (professionalId == null) return;

    changeLoading(true);
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final thirtyDaysAhead = now.add(const Duration(days: 30));

      final response = await _appointmentRepository.getProfessionalAppointments(
        professionalId: professionalId,
        startAt: thirtyDaysAgo,
        endAt: thirtyDaysAhead,
      );

      if (response.success && response.data != null) {
        _allAppointments = response.data!;
        _allAppointments.sort((a, b) => b.startAt.compareTo(a.startAt));
      } else {
        _allAppointments = [];
      }
    } finally {
      changeLoading(false);
      update();
    }
  }

  void changeTab(int tab) {
    currentTab = tab;
    update();
  }

  void onSearchChanged(String query) {
    searchQuery = query;
    update();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  List<ProfessionalAppointmentModel> get filteredPatients {
    List<ProfessionalAppointmentModel> filtered;

    if (currentTab == 0) {
      // Ativos: consultas agendadas (inclui marcadas e em andamento)
      filtered = _allAppointments
          .where((a) => a.status == AppointmentStatus.scheduled)
          .toList();
    } else {
      // Histórico: consultas canceladas, concluídas e não compareceu
      filtered = _allAppointments
          .where(
            (a) =>
                a.status == AppointmentStatus.cancelled ||
                a.status == AppointmentStatus.completed ||
                a.status == AppointmentStatus.noShow,
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.patientName.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return filtered;
  }

  Future<void> markAsCompleted(String appointmentId) async {
    final appointment = _allAppointments.firstWhereOrNull(
      (a) => a.id == appointmentId,
    );
    if (appointment == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Marcar como concluída'),
        content: Text(
          'Deseja marcar a consulta com ${appointment.patientName} como concluída?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentRepository.markAppointmentAsCompleted(appointmentId);
      AppSnackbar.to.show('Consulta marcada como concluída');
      await loadAppointments();
    } catch (e) {
      AppSnackbar.to.show('Erro ao marcar consulta como concluída');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final appointment = _allAppointments.firstWhereOrNull(
      (a) => a.id == appointmentId,
    );
    if (appointment == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancelar consulta'),
        content: Text(
          'Deseja cancelar a consulta com ${appointment.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentRepository.cancelAppointment(appointmentId);
      AppSnackbar.to.show('Consulta cancelada');
      await loadAppointments();
    } catch (e) {
      AppSnackbar.to.show('Erro ao cancelar consulta');
    }
  }

  void navigateToAppointmentDetails(ProfessionalAppointmentModel appointment) {
    Get.toNamed(
      AppointmentDetailsRoutes.appointmentDetails,
      arguments: appointment.id,
    )?.then((result) {
      if (result == true) {
        loadAppointments();
      }
    });
  }

  Future<void> onReschedule(ProfessionalAppointmentModel appointment) async {
    final context = Get.context;
    if (context == null) return;

    final result = await RescheduleBottomSheet.show<String>(
      context,
      appointment,
    );

    switch (result) {
      case 'message':
        await _openWhatsApp(appointment);
        break;
      case 'confirmed':
        AppSnackbar.to.show('Consulta reagendada com sucesso!');
        await loadAppointments();
        break;
      case 'cancelled':
        break;
      default:
        break;
    }
  }

  Future<void> _openWhatsApp(ProfessionalAppointmentModel appointment) async {
    final rawPhone = appointment.patientPhone;
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      AppSnackbar.to.show('Paciente não possui telefone cadastrado.');
      return;
    }

    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      AppSnackbar.to.show('Telefone do paciente é inválido.');
      return;
    }
    final whatsappPhone = cleanPhone.startsWith('55')
        ? cleanPhone
        : '55$cleanPhone';

    final uri = Uri.parse('https://wa.me/$whatsappPhone');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppSnackbar.to.show('Não foi possível abrir o WhatsApp.');
    }
  }
}
