import 'package:url_launcher/url_launcher.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/utils/consultation_rules.dart';
import '../../consultations/consultation_detail_page.dart';
import '../../professionals/booking/booking_page.dart';

/// Opções da consulta para o paciente (card do Dashboard e "Consulta
/// agendada" do planner): ver detalhes, remarcar, WhatsApp e cancelar.
abstract final class PatientAppointmentOptionsSheet {
  /// Abre "Sua consulta" (canvas Q2). Devolve true se a consulta foi
  /// remarcada ou cancelada (quem chamou recarrega a tela).
  static Future<bool> show(ProfessionalAppointmentModel appointment) =>
      ConsultationDetailPage.open(appointment);

  /// Igual a [show], para quando só se tem o id (item do planner).
  static Future<bool> showById(String appointmentId) async {
    final response = await AppointmentRepository().getAppointmentById(
      appointmentId,
    );
    final appointment = response.data;
    if (!response.success || appointment == null) {
      AppSnackbar.to.show('Não foi possível abrir a consulta.');
      return false;
    }
    return show(appointment);
  }

  /// Prazos em [ConsultationRules], os mesmos que o banco confere.
  static bool canChange(ProfessionalAppointmentModel appointment) =>
      ConsultationRules.canReschedule(appointment) ||
      ConsultationRules.canCancel(appointment);

  static Map<String, dynamic>? _professionalUser(
    ProfessionalAppointmentModel appointment,
  ) => appointment.professionalData?['user'] as Map<String, dynamic>?;

  static Future<bool> reschedule(
    ProfessionalAppointmentModel appointment,
  ) async {
    // Mesma tela do agendamento novo, em modo remarcação.
    return BookingPage.reschedule(appointment);
  }

  static Future<void> openWhatsApp(
    ProfessionalAppointmentModel appointment,
  ) async {
    final phone = (_professionalUser(appointment)?['phone']?.toString() ?? '')
        .replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      AppSnackbar.to.show('Telefone do profissional não disponível.');
      return;
    }
    final whatsappPhone = phone.startsWith('55') ? phone : '55$phone';
    final launched = await launchUrl(
      Uri.parse('https://wa.me/$whatsappPhone'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      AppSnackbar.to.show('Não foi possível abrir o WhatsApp.');
    }
  }
}
