import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infra/models/professional_with_user_model.dart';
import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/services/subscription_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/dialogs/premium_lock_dialog.dart';
import '../../calendar/widgets/interactive_calendar_base.dart';
import '../widgets/cancel_appointment_dialog.dart';
import '../widgets/schedule_appointment_bottom_sheet.dart';

class ProfessionalDetailsController extends GetxController
    with LoaderManagerMixin {
  final ProfessionalRepository _repository = ProfessionalRepository();
  final AuthService _authService = AuthService.instance;

  late ProfessionalWithUserModel professional;

  @override
  void onInit() {
    super.onInit();
    professional = Get.arguments as ProfessionalWithUserModel;
  }

  bool get canScheduleAppointment => _authService.canScheduleAppointment;
  int get remainingConsultations => _authService.remainingConsultations;
  bool get isInTrial => _authService.isInTrial;
  bool get hasActivePlan =>
      _authService.accessStatus == SubscriptionAccessStatus.active;

  Future<void> handleScheduleAction() async {
    if (professional.hasAppointment) {
      await _showCancelDialog();
    } else {
      await _showScheduleDialog();
    }
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await CancelAppointmentDialog.show(
      Get.context!,
      professional,
    );

    if (confirmed == true) {
      changeLoading(true);
      final appointmentId = professional.appointmentId;
      if (appointmentId == null) {
        AppSnackbar.to.show('Nenhum agendamento ativo para cancelar.');
        changeLoading(false);
        return;
      }

      final response = await _repository.cancelAppointment(appointmentId);
      changeLoading(false);

      if (!response.success) {
        AppSnackbar.to.show(response.message);
      } else {
        AppSnackbar.to.show('Agendamento cancelado com sucesso');
        // Update local state
        professional = professional.copyWith(clearAppointment: true);
        update();
      }
    }
  }

  Future<void> _showScheduleDialog() async {
    await _authService.reloadUserAccessInfo();
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
      openWhatsApp();
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
        AppSnackbar.to.show('Agendamento realizado com sucesso');
        await _authService.reloadUserAccessInfo();
        // Ideally we would reload the professional data here to get the appointment details
        // For now we can just go back or show success
        Get.back();
      }
    }
  }

  Future<void> openWhatsApp() async {
    await _authService.reloadUserAccessInfo();
    if (!hasActivePlan) {
      Get.dialog(
        PremiumLockDialog(
          message: isInTrial
              ? 'O contato com profissionais não está disponível durante o período de trial. '
                  'Assine um plano para entrar em contato!'
              : 'Você precisa de uma assinatura ativa para entrar em contato com os profissionais. '
                  'Assine um plano para ter acesso!',
          contentType: 'Contato',
          contentTitle: professional.user.fullName,
        ),
      );
      return;
    }

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
}
