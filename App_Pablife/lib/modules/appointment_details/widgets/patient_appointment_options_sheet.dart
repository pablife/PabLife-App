import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/whatsapp_icon.dart';
import '../../calendar/widgets/interactive_calendar_base.dart';
import '../appointment_details_routes.dart';
import 'reschedule_time_picker_page.dart';

/// Opções da consulta para o paciente (card do Dashboard e "Consulta
/// agendada" do planner): ver detalhes, remarcar, WhatsApp e cancelar.
class PatientAppointmentOptionsSheet extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;

  const PatientAppointmentOptionsSheet({super.key, required this.appointment});

  /// Abre as opções. Devolve true se a consulta foi remarcada ou cancelada
  /// (quem chamou recarrega a tela).
  static Future<bool> show(ProfessionalAppointmentModel appointment) async {
    final result = await Get.bottomSheet<String>(
      PatientAppointmentOptionsSheet(appointment: appointment),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    switch (result) {
      case 'details':
        await Get.toNamed(
          AppointmentDetailsRoutes.appointmentDetails,
          arguments: appointment.id,
        );
        return true;
      case 'reschedule':
        return _reschedule(appointment);
      case 'whatsapp':
        await _openWhatsApp(appointment);
        return false;
      case 'cancel':
        return _cancel(appointment);
      default:
        return false;
    }
  }

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

  /// Remarcar e cancelar seguem a regra do app: até 24h antes.
  static bool canChange(ProfessionalAppointmentModel appointment) =>
      appointment.status == AppointmentStatus.scheduled &&
      appointment.startAt.isAfter(
        DateTime.now().add(const Duration(hours: 24)),
      );

  static Map<String, dynamic>? _professionalUser(
    ProfessionalAppointmentModel appointment,
  ) => appointment.professionalData?['user'] as Map<String, dynamic>?;

  static Future<bool> _reschedule(
    ProfessionalAppointmentModel appointment,
  ) async {
    final slot = await Get.to<CalendarSlotData>(
      () =>
          RescheduleTimePickerPage(professionalId: appointment.professionalId),
    );
    if (slot == null) return false;

    final newDate = DateFormat(
      "dd/MM 'às' HH:mm",
      'pt_BR',
    ).format(slot.startAt.toLocal());
    final confirmed = await _confirm(
      title: 'Remarcar consulta',
      message: 'Remarcar sua consulta para $newDate?',
      confirmText: 'Remarcar',
      confirmColor: const Color(0xFF0C8DA1),
    );
    if (!confirmed) return false;

    final response = await AppointmentRepository().rescheduleAppointment(
      appointmentId: appointment.id,
      newAppointmentTimeId: slot.id,
      newSlotStartAt: slot.startAt,
    );
    if (!response.success) {
      AppSnackbar.to.show(response.message);
      return false;
    }
    AppSnackbar.to.show('Consulta remarcada para $newDate');
    return true;
  }

  static Future<bool> _cancel(ProfessionalAppointmentModel appointment) async {
    final confirmed = await _confirm(
      title: 'Cancelar consulta',
      message:
          'Tem certeza que deseja cancelar esta consulta? Esta ação não pode ser desfeita.',
      confirmText: 'Cancelar consulta',
      confirmColor: const Color(0xFFFF5252),
    );
    if (!confirmed) return false;

    try {
      await AppointmentRepository().cancelAppointment(appointment.id);
    } catch (_) {
      AppSnackbar.to.show('Não foi possível cancelar a consulta.');
      return false;
    }
    AppSnackbar.to.show('Consulta cancelada');
    return true;
  }

  static Future<void> _openWhatsApp(
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

  static Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AppDialog(
        title: title,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextDefault(
            message,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(204),
            textAlign: TextAlign.center,
          ),
        ),
        confirmText: confirmText,
        cancelText: 'Voltar',
        confirmButtonColor: confirmColor,
        cancelButtonColor: const Color(0xFF0C8DA1),
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final professional = _professionalUser(appointment);
    final type = appointment.professionalData?['type'];
    final typeLabel = type == 'psychologist'
        ? 'Psicólogo(a)'
        : type == 'nutritionist'
        ? 'Nutricionista'
        : 'Profissional';
    final when = DateFormat(
      "EEE, d 'de' MMMM · HH:mm",
      'pt_BR',
    ).format(appointment.startAt.toLocal());
    final changeable = canChange(appointment);
    final isScheduled = appointment.status == AppointmentStatus.scheduled;
    final hasPhone = (professional?['phone']?.toString() ?? '').isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF00343C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: AppImage(
                        imageUrl: professional?['image_url']?.toString(),
                        width: 56,
                        height: 56,
                        errorWidget: Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF89BEC6),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextDefault(
                            typeLabel,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                          TextDefault(
                            professional?['full_name']?.toString() ??
                                'Profissional',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextDefault(
                            when,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9FE1CB),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _option(
                  icon: const Icon(Icons.description_outlined),
                  label: 'Ver detalhes da consulta',
                  result: 'details',
                ),
                if (changeable)
                  _option(
                    icon: const Icon(Icons.event_repeat),
                    label: 'Remarcar consulta',
                    result: 'reschedule',
                  ),
                if (hasPhone)
                  _option(
                    icon: const WhatsAppIcon(size: 22),
                    label: 'Conversar no WhatsApp',
                    result: 'whatsapp',
                    background: const Color(0xFF25D366),
                    foreground: Colors.white,
                  ),
                if (changeable)
                  _option(
                    icon: const Icon(Icons.close),
                    label: 'Cancelar consulta',
                    result: 'cancel',
                    background: const Color(0xFFDA879A),
                    foreground: const Color(0xFF4A1B0C),
                  ),
                if (isScheduled && !changeable)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: TextDefault(
                      'Remarcar e cancelar ficam disponíveis até 24h antes da consulta.',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option({
    required Widget icon,
    required String label,
    required String result,
    Color background = const Color(0xFFC1CDFF),
    Color foreground = const Color(0xFF00343C),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.back(result: result),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 22),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextDefault(
                      label,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
