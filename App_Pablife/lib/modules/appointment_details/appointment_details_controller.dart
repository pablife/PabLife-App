import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/professional_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/patient_record_model.dart';
import '../../infra/models/professional_appointment_model.dart';
import '../../infra/models/user_role.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/patient_record_repository.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/design_system/app_dialog.dart';
import '../home/controllers/professional_home_controller.dart';
import '../home/controllers/user_home_controller.dart';
import '../patients/patients_controller.dart';
import 'record_editor/record_editor_arguments.dart';
import 'record_editor/record_editor_page.dart';

class AppointmentDetailsController extends GetxController
    with LoaderManagerMixin {
  final authService = AuthService.instance;
  final appointmentRepository = AppointmentRepository();
  final patientRecordRepository = PatientRecordRepository();
  final professionalRepository = ProfessionalRepository();

  ProfessionalAppointmentModel? appointment;
  bool isLoadingAppointment = true;

  List<String> tabs = [];
  Map<String, PatientRecordType> tabTypeMap = {};

  String currentTab = '';

  List<PatientRecordModel> allRecords = [];

  String? patientId;

  List<PatientRecordType> get availableRecordTypes =>
      LinkedHashSet<PatientRecordType>.from(tabTypeMap.values).toList();

  bool isFabExpanded = false;

  @override
  void onInit() {
    super.onInit();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    try {
      isLoadingAppointment = true;
      update();

      final args = Get.arguments;
      String? appointmentId;

      // Aceita tanto o ID direto quanto um ProfessionalAppointmentModel com ID
      if (args is String) {
        appointmentId = args;
      } else if (args is ProfessionalAppointmentModel) {
        appointmentId = args.id;
      } else if (args is Map && args['id'] != null) {
        appointmentId = args['id'];
      }

      if (appointmentId == null) {
        throw Exception('ID da consulta não fornecido');
      }

      // Recarrega os dados completos da consulta do repository
      final response = await appointmentRepository.getAppointmentById(
        appointmentId,
      );

      if (!response.success || response.data == null) {
        throw Exception('Consulta não encontrada');
      }

      appointment = response.data;

      await initialize();
    } catch (e) {
      AppSnackbar.to.show('Erro ao carregar consulta: $e');
      Get.back();
    } finally {
      isLoadingAppointment = false;
      update();
    }
  }

  Future<void> initialize() async {
    if (appointment == null) return;

    changeLoading(true);

    // Don't load tabs and records for non-scheduled appointments
    // or for scheduled appointments that haven't started yet
    if ((appointment!.status != AppointmentStatus.scheduled &&
            appointment!.status != AppointmentStatus.completed) ||
        (appointment!.status == AppointmentStatus.scheduled &&
            appointment!.startedAt == null)) {
      changeLoading(false);
      update();
      return;
    }

    await setupTabs();

    await loadRecords();
  }

  ProfessionalModel? professional;
  Future<void> setupTabs() async {
    // Busca o tipo do profissional da consulta, não do usuário logado
    final professionalId = appointment!.professionalId;

    final response = await professionalRepository.getProfessionalById(
      professionalId,
    );

    professional = response.data;
    final professionalType = professional?.type;

    if (professionalType == 'psychologist') {
      tabs = ['Anotações', 'Reflexões', 'Práticas'];
      tabTypeMap = {
        'Anotações': PatientRecordType.note,
        'Reflexões': PatientRecordType.reflection,
        'Práticas': PatientRecordType.practice,
      };
    } else if (professionalType == 'nutritionist') {
      tabs = ['Plano Alimentar', 'Receitas', 'Observações'];
      tabTypeMap = {
        'Plano Alimentar': PatientRecordType.mealPlan,
        'Receitas': PatientRecordType.prescription,
        'Observações': PatientRecordType.observation,
      };
    }

    currentTab = tabs.isNotEmpty ? tabs.first : '';
  }

  Future<void> loadRecords() async {
    changeLoading(true);
    try {
      // Busca o patient_id correto da tabela tb_patients através do appointment_id
      final patientIdResponse = await patientRecordRepository
          .getPatientIdByAppointment(appointment!.id);

      final fetchedPatientId = patientIdResponse.data;
      patientId = fetchedPatientId;

      if (fetchedPatientId == null || fetchedPatientId.isEmpty) {
        debugPrint(
          '⚠️ [AppointmentDetails] Nenhum patient_id encontrado na tabela tb_patients',
        );
        allRecords = [];
        return;
      }

      final response = await patientRecordRepository.getPatientRecords(
        patientId: fetchedPatientId,
      );

      if (response.success && response.data != null) {
        allRecords = response.data!;
        debugPrint(
          '✅ [AppointmentDetails] ${allRecords.length} registros carregados',
        );
      }
    } finally {
      changeLoading(false);
      update();
    }
  }

  void changeTab(String tab) {
    currentTab = tab;
    update();
  }

  void onFabExpandedChanged(bool value) {
    isFabExpanded = value;
    update();
  }

  List<PatientRecordModel> get filteredRecords {
    final type = tabTypeMap[currentTab];
    if (type == null) return [];

    return allRecords.where((record) => record.type == type).toList();
  }

  Future<void> openWhatsApp() async {
    final rawPhone = appointment!.patientPhone;
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      AppSnackbar.to.show(
        isPatient
            ? 'Profissional não possui telefone cadastrado.'
            : 'Paciente não possui telefone cadastrado.',
      );
      return;
    }

    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      AppSnackbar.to.show(
        isPatient
            ? 'Telefone do profissional é inválido.'
            : 'Telefone do paciente é inválido.',
      );
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

  void onCreateRecord(PatientRecordType type) async {
    if (patientId == null || patientId!.isEmpty) {
      AppSnackbar.to.show('Não foi possível identificar o paciente.');
      return;
    }

    final result = await Get.toNamed(
      RecordEditorPage.route,
      arguments: RecordEditorArguments(
        type: type,
        patientId: patientId!,
        appointmentId: appointment!.id,
      ),
    );

    if (result == true) {
      await loadRecords();
    }
  }

  void onEditRecord(PatientRecordModel record) async {
    if (isPatient) return;

    if (patientId == null || patientId!.isEmpty) {
      AppSnackbar.to.show('Não foi possível identificar o paciente.');
      return;
    }

    final result = await Get.toNamed(
      RecordEditorPage.route,
      arguments: RecordEditorArguments(
        type: record.type,
        patientId: patientId!,
        appointmentId: appointment!.id,
        record: record,
      ),
    );

    if (result == true) {
      await loadRecords();
    }
  }

  bool get isPatient {
    return authService.currentUser?.role == UserRole.user;
  }

  bool get shouldShowCancelButton {
    if (appointment!.isCompleted) return false;

    // Patients can cancel if it's more than 24h before? Or same rule?
    // For now, using same rule but can be customized.

    final now = DateTime.now();
    final tenMinutesAfterStart = appointment!.startAt.add(
      const Duration(minutes: 10),
    );

    return now.isAfter(tenMinutesAfterStart);
  }

  /// Atualiza as telas iniciais após alteração no appointment
  void _refreshHomeControllers() {
    // Atualiza home do paciente
    try {
      final userHomeController = UserHomeController.to;
      userHomeController.refreshData();
    } catch (e) {
      // UserHomeController não está instanciado
    }

    // Atualiza home do profissional
    try {
      final professionalHomeController = ProfessionalHomeController.to;
      professionalHomeController.refreshData();
    } catch (e) {
      // ProfessionalHomeController não está instanciado
    }
  }

  Future<void> promptCancelAppointment() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Cancelar consulta',
      message:
          'Tem certeza que deseja cancelar esta consulta? Esta ação não pode ser desfeita.',
      confirmText: 'Cancelar',
      cancelText: 'Não',
      confirmButtonColor: Colors.redAccent,
    );

    if (confirmed == true) {
      await appointmentRepository.cancelAppointment(appointment!.id);

      AppSnackbar.to.show('Consulta cancelada com sucesso');

      _refreshHomeControllers();

      Get.back(result: true);
    }
  }

  bool get canShowStartButton {
    if (isPatient) return false;

    if (appointment!.status != AppointmentStatus.scheduled ||
        appointment!.startedAt != null) {
      return false;
    }

    // Show only 10 minutes before appointment
    final now = DateTime.now();
    final tenMinutesBefore = appointment!.startAt.subtract(
      const Duration(minutes: 10),
    );
    return now.isAfter(tenMinutesBefore);
  }

  bool get canShowNoShowButton {
    if (isPatient) return false;
    return appointment!.canMarkNoShow;
  }

  bool get canShowCompleteButton {
    if (isPatient) return false;
    return appointment!.startedAt != null &&
        appointment!.status == AppointmentStatus.scheduled;
  }

  Future<void> completeAppointment() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Concluir consulta',
      message: 'Tem certeza que deseja concluir esta consulta?',
      confirmText: 'Concluir',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.green,
    );

    if (confirmed == true) {
      changeLoading(true);
      try {
        await appointmentRepository.completeAppointment(appointment!.id);

        // Update the appointment status and finished_at
        appointment = appointment!.copyWith(
          status: AppointmentStatus.completed,
          finishedAt: DateTime.now(),
        );

        final patientsController = Get.isRegistered<PatientsController>()
            ? Get.find<PatientsController>()
            : null;
        await patientsController?.loadAppointments();

        // Atualiza as telas iniciais
        _refreshHomeControllers();

        AppSnackbar.to.show('Consulta concluída com sucesso');
      } catch (e) {
        AppSnackbar.to.show('Erro ao concluir consulta');
      } finally {
        changeLoading(false);
        update();
      }
    }
  }

  Future<void> startAppointment() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Iniciar consulta',
      message: 'Tem certeza que deseja iniciar esta consulta agora?',
      confirmText: 'Iniciar',
      cancelText: 'Cancelar',
      confirmButtonColor: const Color(0xFF0C8DA1),
    );

    if (confirmed != true) {
      return;
    }

    changeLoading(true);
    try {
      await appointmentRepository.startAppointment(appointment!.id);

      // Update the appointment with started_at
      appointment = appointment!.copyWith(startedAt: DateTime.now());

      // Reload tabs and records now that the appointment has started
      await initialize();

      AppSnackbar.to.show('Consulta iniciada com sucesso');

      final patientsController = Get.isRegistered<PatientsController>()
          ? Get.find<PatientsController>()
          : null;
      await patientsController?.loadAppointments();

      // Atualiza as telas iniciais
      _refreshHomeControllers();
    } catch (e) {
      AppSnackbar.to.show('Erro ao iniciar consulta');
    } finally {
      changeLoading(false);
      update();
    }
  }

  Future<void> markNoShow() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Paciente não compareceu',
      message:
          'Tem certeza que deseja marcar que o paciente não compareceu? Esta ação não pode ser desfeita.',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.orangeAccent,
    );

    if (confirmed == true) {
      changeLoading(true);
      try {
        await appointmentRepository.markNoShow(appointment!.id);

        // Update the appointment status
        appointment = appointment!.copyWith(status: AppointmentStatus.noShow);

        AppSnackbar.to.show('Consulta marcada como não compareceu');

        final patientsController = Get.isRegistered<PatientsController>()
            ? Get.find<PatientsController>()
            : null;
        await patientsController?.loadAppointments();

        // Atualiza as telas iniciais
        _refreshHomeControllers();
      } catch (e) {
        AppSnackbar.to.show('Erro ao marcar consulta');
      } finally {
        changeLoading(false);
        update();
      }
    }
  }

  bool get shouldShowWhatsAppButton {
    // Don't show if cancelled or no_show
    if (appointment!.status == AppointmentStatus.cancelled ||
        appointment!.status == AppointmentStatus.noShow) {
      return false;
    }

    // Show if appointment has started
    if (appointment!.startedAt != null) {
      return true;
    }

    // Show 10 minutes before appointment if scheduled
    if (appointment!.status == AppointmentStatus.scheduled) {
      final now = DateTime.now();
      final tenMinutesBefore = appointment!.startAt.subtract(
        const Duration(minutes: 10),
      );
      return now.isAfter(tenMinutesBefore);
    }

    return false;
  }

  bool get shouldShowAddRecordButton {
    if (isPatient) return false;

    // Don't show if cancelled or no_show
    if (appointment!.status == AppointmentStatus.cancelled ||
        appointment!.status == AppointmentStatus.noShow) {
      return false;
    }

    if (appointment!.status == AppointmentStatus.completed) {
      return false;
    }

    // Show only if appointment has started
    return appointment!.startedAt != null;
  }
}
