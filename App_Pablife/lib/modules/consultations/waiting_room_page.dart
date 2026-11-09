import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/design_system/whatsapp_icon.dart';
import '../appointment_details/widgets/patient_appointment_options_sheet.dart';
import '../auth/pages/widgets/registration_layout.dart';
import 'consultation_detail_page.dart';
import 'consultation_info.dart';

/// "Sala de espera" (canvas Q4): quem vai atender, dicas antes de começar e
/// "Entrar na consulta", que abre a sala de vídeo do profissional.
class WaitingRoomPage extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;

  const WaitingRoomPage({super.key, required this.appointment});

  static Future<void> open(ProfessionalAppointmentModel appointment) =>
      Get.to<void>(() => WaitingRoomPage(appointment: appointment)) ??
      Future.value();

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  bool _opening = false;

  Future<void> _enter() async {
    if (_opening) return;
    setState(() => _opening = true);
    final url = await ConsultationRepository().meetingUrl(
      widget.appointment.id,
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (url == null) {
      AppSnackbar.to.show(
        widget.appointment.roomOpen()
            ? 'A sala ainda não foi cadastrada pelo profissional. Fale com '
                  'ele pelo WhatsApp.'
            : 'A sala abre 15 minutos antes da consulta.',
      );
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok) AppSnackbar.to.show('Não foi possível abrir a sala.');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final me = AuthService.instance.currentUser?.fullName ?? '';
    final myInitials = me
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final first = a.professionalName.split(' ').first;

    Widget tip(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: PabColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFFDCE7E6)),
            ),
          ),
        ],
      ),
    );

    return PabCardFrame(
      background: PabColors.ink,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DarkBackButton(onTap: () => Get.back<void>()),
                  const SizedBox(width: 12),
                  const Text(
                    'Sala de espera',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PabColors.onInk,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 16),
                  children: [
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: PabColors.onInk.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: PabColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              myInitials.isEmpty ? '?' : myInitials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: PabColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Câmera e microfone você liga na sala, ao '
                              'entrar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: PabColors.onInkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Consulta com $first às ${a.time}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: PabColors.onInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'O profissional entra na sala no horário marcado.',
                      style: TextStyle(fontSize: 14, color: PabColors.navIdle),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PabColors.onInk.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Antes de começar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: PabColors.onInk,
                            ),
                          ),
                          tip('Um lugar tranquilo e reservado'),
                          tip('Fone de ouvido, se tiver'),
                          tip('Internet estável e bateria carregada'),
                        ],
                      ),
                    ),
                    if (a.professionalPhone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            PatientAppointmentOptionsSheet.openWhatsApp(a),
                        icon: const WhatsAppIcon(
                          size: 18,
                          color: WhatsAppIcon.green,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: PabColors.onInkSoft,
                          minimumSize: const Size(0, 44),
                        ),
                        label: const Text(
                          'Problema para entrar? Fale no WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RegPrimaryButton(
                label: _opening ? 'Abrindo a sala…' : 'Entrar na consulta',
                loading: _opening,
                onTap: _enter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
