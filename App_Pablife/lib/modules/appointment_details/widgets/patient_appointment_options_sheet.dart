import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/repositories/appointment_repository.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/utils/consultation_rules.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/whatsapp_icon.dart';
import '../../calendar/widgets/calendar_connect_dialog.dart';
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
      case 'calendar':
        final context = Get.context;
        if (context != null && context.mounted) {
          await CalendarConnectDialog.show(context);
        }
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

  /// Prazos em [ConsultationRules], os mesmos que o banco confere.
  static bool canChange(ProfessionalAppointmentModel appointment) =>
      ConsultationRules.canReschedule(appointment) ||
      ConsultationRules.canCancel(appointment);

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
      confirmColor: const AppColor(0xFF0C8DA1),
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
    final returns = ConsultationRules.cancelReturnsToBalance(appointment);
    final confirmed = await _confirm(
      title: 'Cancelar consulta',
      message: returns
          ? 'Tem certeza que deseja cancelar esta consulta? Ela volta para o '
                'seu saldo.'
          : 'Faltam menos de 24 horas para a consulta. Se cancelar agora, ela '
                'não volta para o seu saldo.',
      confirmText: 'Cancelar consulta',
      confirmColor: const AppColor(0xFFFF5252),
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
        cancelButtonColor: const AppColor(0xFF0C8DA1),
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
    final start = appointment.startAt.toLocal();
    final day = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(start);
    final time = DateFormat('HH:mm').format(start);
    final canReschedule = ConsultationRules.canReschedule(appointment);
    final canCancel = ConsultationRules.canCancel(appointment);
    final isScheduled = appointment.status == AppointmentStatus.scheduled;
    final hasPhone = (professional?['phone']?.toString() ?? '').isNotEmpty;
    final name = professional?['full_name']?.toString() ?? 'Profissional';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: const BoxDecoration(
            color: PabColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Topo escuro: dia, hora em destaque e modalidade.
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    decoration: const BoxDecoration(
                      color: PabColors.ink,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua consulta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${day[0].toUpperCase()}${day.substring(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Online por vídeo',
                          style: TextStyle(
                            fontSize: 13,
                            color: PabColors.navIdle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfessionalCard(
                          name: name,
                          role: typeLabel,
                          imageUrl: professional?['image_url']?.toString(),
                          onWhatsApp: hasPhone
                              ? () => Get.back(result: 'whatsapp')
                              : null,
                        ),
                        if (isScheduled) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: PabColors.soft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Você recebe lembretes 3 dias, 1 dia e 1 hora '
                              'antes. ${ConsultationRules.limitsText(appointment)}',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: PabColors.softText,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: PabColors.card,
                            border: Border.all(color: PabColors.line),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _row('Ver detalhes da consulta', 'details'),
                              if (isScheduled) ...[
                                const Divider(height: 1, color: PabColors.line),
                                _row(
                                  'Adicionar ao calendário do celular',
                                  'calendar',
                                ),
                              ],
                              if (canReschedule) ...[
                                const Divider(height: 1, color: PabColors.line),
                                _row('Remarcar', 'reschedule'),
                              ],
                            ],
                          ),
                        ),
                        if (canCancel) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => Get.back(result: 'cancel'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: PabColors.card,
                              foregroundColor: PabColors.error,
                              side: const BorderSide(
                                color: PabColors.errorLine,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancelar consulta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String result) {
    return InkWell(
      onTap: () => Get.back(result: result),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: PabColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final String name;
  final String role;
  final String? imageUrl;
  final VoidCallback? onWhatsApp;

  const _ProfessionalCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.length > 2)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipOval(
            child: AppImage(
              imageUrl: imageUrl,
              width: 52,
              height: 52,
              errorWidget: Container(
                width: 52,
                height: 52,
                color: PabColors.lilac,
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PabColors.lilacText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(fontSize: 13, color: PabColors.muted),
                ),
              ],
            ),
          ),
          if (onWhatsApp != null)
            Tooltip(
              message: 'Conversar no WhatsApp',
              child: Material(
                color: PabColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: PabColors.lineStrong),
                ),
                child: InkWell(
                  onTap: onWhatsApp,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: WhatsAppIcon(size: 20)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
