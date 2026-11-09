import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/consultation_rules.dart';
import '../../widgets/design_system/whatsapp_icon.dart';
import '../appointment_details/widgets/patient_appointment_options_sheet.dart';
import '../auth/pages/widgets/registration_layout.dart';
import '../calendar/widgets/calendar_connect_dialog.dart';
import 'cancel_consultation_page.dart';
import 'consultation_info.dart';
import 'waiting_room_page.dart';

/// "Sua consulta" (canvas Q2): dia e hora em destaque, profissional com
/// WhatsApp, aviso dos lembretes, "Entrar na sala", calendário, remarcar e
/// cancelar. Devolve true quando a consulta mudou (remarcada ou cancelada).
class ConsultationDetailPage extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;

  const ConsultationDetailPage({super.key, required this.appointment});

  static Future<bool> open(ProfessionalAppointmentModel appointment) async {
    final changed = await Get.to<bool>(
      () => ConsultationDetailPage(appointment: appointment),
    );
    return changed ?? false;
  }

  Future<void> _reschedule() async {
    final changed = await PatientAppointmentOptionsSheet.reschedule(
      appointment,
    );
    if (changed) Get.back(result: true);
  }

  Future<void> _cancel() async {
    final cancelled = await CancelConsultationPage.open(appointment);
    if (cancelled) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final scheduled = a.status == AppointmentStatus.scheduled;
    final canReschedule = ConsultationRules.canReschedule(a);
    final canCancel = ConsultationRules.canCancel(a);
    final open = a.roomOpen();

    Widget row(String label, VoidCallback onTap, {bool last = false}) =>
        InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: PabColors.line)),
            ),
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
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: PabColors.muted,
                ),
              ],
            ),
          ),
        );

    final rows = [
      if (scheduled)
        (
          'Adicionar ao calendário do celular',
          () => CalendarConnectDialog.show(context),
        ),
      if (canReschedule) ('Remarcar', _reschedule),
    ];

    return PabCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: PabColors.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DarkBackButton(
                          onTap: () => Get.back<bool>(result: false),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sua consulta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      a.longDay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PabColors.onInkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.time,
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: PabColors.onInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduled
                          ? 'Online por vídeo · horário de Brasília'
                          : a.statusLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PabColors.navIdle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PabColors.card,
                    border: Border.all(color: PabColors.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ProfessionalAvatarCircle(appointment: a),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.professionalName,
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
                              a.professionalRole,
                              style: const TextStyle(
                                fontSize: 13,
                                color: PabColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (a.professionalPhone.isNotEmpty)
                        Tooltip(
                          message: 'Conversar no WhatsApp',
                          child: Material(
                            color: PabColors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: PabColors.lineStrong,
                              ),
                            ),
                            child: InkWell(
                              onTap: () =>
                                  PatientAppointmentOptionsSheet.openWhatsApp(
                                    a,
                                  ),
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: WhatsAppIcon(
                                    size: 22,
                                    color: WhatsAppIcon.green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (scheduled) ...[
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
                      'A sala abre 15 minutos antes. Você recebe lembretes '
                      '3 dias, 1 dia e 1 hora antes. '
                      '${ConsultationRules.limitsText(a)}',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: PabColors.softText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: open ? () => WaitingRoomPage.open(a) : null,
                    icon: const Icon(Icons.videocam_outlined, size: 20),
                    label: Text(
                      open ? 'Entrar na sala' : 'A sala abre 15 min antes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      backgroundColor: PabColors.accent,
                      foregroundColor: PabColors.ink,
                      disabledBackgroundColor: PabColors.track,
                      disabledForegroundColor: PabColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PabColors.card,
                      border: Border.all(color: PabColors.line),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          row(
                            rows[i].$1,
                            rows[i].$2,
                            last: i == rows.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: PabColors.card,
                      foregroundColor: PabColors.error,
                      side: const BorderSide(color: PabColors.errorLine),
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
    );
  }
}

/// Botão de voltar dos topos escuros (Sua consulta, Sala de espera).
class DarkBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const DarkBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voltar',
      child: Material(
        color: PabColors.onInk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back, size: 20, color: PabColors.onInk),
          ),
        ),
      ),
    );
  }
}
