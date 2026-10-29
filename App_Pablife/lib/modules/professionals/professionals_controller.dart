import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/models/professional_with_user_model.dart';
import '../../infra/services/auth_service.dart';
import '../../widgets/dialogs/premium_lock_dialog.dart';
import '../calendar/widgets/interactive_calendar_base.dart';
import 'widgets/cancel_appointment_dialog.dart';
import 'widgets/schedule_appointment_bottom_sheet.dart';

class ProfessionalsController extends GetxController with LoaderManagerMixin {
  final ProfessionalRepository _repository = ProfessionalRepository();
  final AuthService _authService = AuthService.instance;

  ProfessionalsController();

  /// Verifica se o usuário pode agendar consultas
  bool get canScheduleAppointment => _authService.canScheduleAppointment;

  /// Retorna quantas consultas restam
  int get remainingConsultations => _authService.remainingConsultations;

  /// Verifica se o usuário está em trial
  bool get isInTrial => _authService.isInTrial;

  final TextEditingController searchController = TextEditingController();

  List<ProfessionalWithUserModel> professionals = [];
  List<ProfessionalWithUserModel> filteredProfessionals = [];
  final List<String> professionalTypes = ['Psicólogos', 'Nutricionistas'];
  String selectedType = 'Psicólogos';
  bool showOnlyScheduled = false;

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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    changeLoading(true);
    await loadProfessionals();
    changeLoading(false);
  }

  Future<void> loadProfessionals() async {
    final response = await _repository.getAllProfessionals();
    if (!response.success) {
      professionals = response.data ?? [];
      _applyFilters();
      update();
      return;
    }

    professionals = response.data ?? [];
    _applyFilters();
    update();
  }

  Future<void> changeType(String type) async {
    if (selectedType == type) return;

    selectedType = type;
    _applyFilters();
    update();
  }

  void toggleScheduledFilter() {
    showOnlyScheduled = !showOnlyScheduled;
    _applyFilters();
    update();
  }

  void _onSearchChanged() {
    _applyFilters();
    update();
  }

  void _applyFilters() {
    List<ProfessionalWithUserModel> tempProfessionals = List.from(
      professionals,
    );

    // Sempre aplica o filtro de tipo
    final typeKey = _getTypeKey(selectedType);
    tempProfessionals = tempProfessionals
        .where((p) => p.professional.type == typeKey)
        .toList();

    if (showOnlyScheduled) {
      tempProfessionals = tempProfessionals
          .where((p) => p.hasAppointment)
          .toList();
    }

    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempProfessionals = tempProfessionals
          .where(
            (p) =>
                p.user.fullName.toLowerCase().contains(query) ||
                p.user.email.toLowerCase().contains(query) ||
                p.typeFormatted.toLowerCase().contains(query),
          )
          .toList();
    }

    filteredProfessionals = tempProfessionals;
  }

  String _getTypeKey(String typeFormatted) {
    switch (typeFormatted) {
      case 'Psicólogos':
        return 'psychologist';
      case 'Nutricionistas':
        return 'nutritionist';
      default:
        return '';
    }
  }

  void openProfessional(ProfessionalWithUserModel professional) {
    Get.toNamed('/professional-details', arguments: professional);
  }

  Future<void> handleCalendarAction(
    ProfessionalWithUserModel professional,
  ) async {
    if (professional.hasAppointment) {
      await _showCancelDialog(professional);
    } else {
      await _showScheduleDialog(professional);
    }
  }

  Future<void> _showCancelDialog(ProfessionalWithUserModel professional) async {
    final confirmed = await CancelAppointmentDialog.show(
      Get.context!,
      professional,
    );

    if (confirmed == true) {
      changeLoading(true);
      final appointmentId = professional.appointmentId;
      if (appointmentId == null) {
        AppSnackbar.to.show('Nenhum agendamento ativo para cancelar.');
        return;
      }

      final response = await _repository.cancelAppointment(appointmentId);
      changeLoading(false);

      if (!response.success) {
        AppSnackbar.to.show(response.message);
      } else {
        AppSnackbar.to.show('Agendamento cancelado com sucesso');
        await loadProfessionals();
      }
    }
  }

  Future<void> _showScheduleDialog(
    ProfessionalWithUserModel professional,
  ) async {
    await _authService.reloadUserAccessInfo();
    // Verificar se o usuário pode agendar consultas
    if (!canScheduleAppointment) {
      if (isInTrial) {
        Get.dialog(
          PremiumLockDialog(
            message:
                'O agendamento de consultas não está disponível durante o período de trial. '
                'Assine um plano para agendar consultas!',
            contentType: 'Consulta',
            contentTitle: professional.user.fullName,
          ),
        );
      } else if (remainingConsultations <= 0) {
        Get.dialog(
          PremiumLockDialog(
            message:
                'Você já utilizou todas as suas consultas deste mês. '
                'Aguarde a renovação ou faça upgrade do seu plano!',
            contentType: 'Consulta',
            contentTitle: professional.user.fullName,
          ),
        );
      } else {
        Get.dialog(
          PremiumLockDialog(
            message:
                'Você precisa de uma assinatura ativa para agendar consultas. '
                'Assine um plano para ter acesso!',
            contentType: 'Consulta',
            contentTitle: professional.user.fullName,
          ),
        );
      }
      return;
    }

    final result = await ScheduleAppointmentBottomSheet.show<dynamic>(
      Get.context!,
      professional,
    );

    if (result == 'message') {
      _openWhatsApp(professional);
      return;
    }

    if (result is CalendarSlotData) {
      changeLoading(true);
      final response = await _repository.scheduleAppointment(
        professionalId: professional.professional.id!,
        appointmentTimeId: result.id,
        slotStartAt: result.startAt,
      );
      changeLoading(false);

      if (!response.success) {
        AppSnackbar.to.show(response.message);
      } else {
        // Recarregar informações de assinatura após agendar
        await _authService.reloadUserAccessInfo();
        await loadProfessionals();

        // Navegar para tela de sucesso
        Get.offAllNamed('/appointment-success');
      }
    }
  }

  Future<void> _openWhatsApp(ProfessionalWithUserModel professional) async {
    final phone = professional.user.phone;
    if (phone.isEmpty) {
      AppSnackbar.to.show('Telefone do profissional não disponível');
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappPhone = cleanPhone.startsWith('55')
        ? cleanPhone
        : '55$cleanPhone';
    final url = Uri.parse('https://wa.me/$whatsappPhone');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        AppSnackbar.to.show('Não foi possível abrir o WhatsApp.');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao abrir WhatsApp: ${e.toString()}');
    }
  }

  void openNotifications() {
    Get.toNamed('/notifications');
  }
}
