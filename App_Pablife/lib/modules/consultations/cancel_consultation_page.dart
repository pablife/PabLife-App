import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/consultation_rules.dart';
import '../appointment_details/widgets/patient_appointment_options_sheet.dart';
import '../auth/pages/widgets/registration_layout.dart';
import 'consultation_cancelled_page.dart';
import 'consultation_info.dart';

/// "Cancelar consulta" (canvas Q3): resumo, regra do saldo, motivo e
/// "Confirmar cancelamento" ou "Prefiro remarcar". Devolve true se cancelou.
class CancelConsultationPage extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;

  const CancelConsultationPage({super.key, required this.appointment});

  static Future<bool> open(ProfessionalAppointmentModel appointment) async {
    final done = await Get.to<bool>(
      () => CancelConsultationPage(appointment: appointment),
    );
    return done ?? false;
  }

  @override
  State<CancelConsultationPage> createState() => _CancelConsultationPageState();
}

class _CancelConsultationPageState extends State<CancelConsultationPage> {
  static const _reasons = [
    'Não vou conseguir no horário',
    'Quero outra profissional',
    'Estou me sentindo melhor',
    'Outro motivo',
  ];

  int _reason = 0;
  bool _sending = false;
  String? _error;

  ProfessionalAppointmentModel get _a => widget.appointment;

  Future<void> _confirm() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final returns = ConsultationRules.cancelReturnsToBalance(_a);
    final error = await ConsultationRepository().cancelWithReason(
      _a.id,
      _reasons[_reason],
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _sending = false;
        _error = error;
      });
      return;
    }
    // Mostra "Consulta cancelada" e avisa quem abriu que mudou.
    await Get.to<void>(
      () => ConsultationCancelledPage(
        appointment: _a,
        returnedToBalance: returns,
      ),
    );
    Get.back(result: true);
  }

  Future<void> _reschedule() async {
    final changed = await PatientAppointmentOptionsSheet.reschedule(_a);
    if (changed) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final returns = ConsultationRules.cancelReturnsToBalance(_a);
    final canReschedule = ConsultationRules.canReschedule(_a);

    return RegistrationLayout(
      title: 'Cancelar consulta',
      onBack: () => Get.back(result: false),
      fields: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _a.shortWhen,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_a.professionalName} · ${_a.professionalRole}',
                style: const TextStyle(fontSize: 13, color: PabColors.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            returns
                ? 'Cancelando até 24 horas antes, a consulta volta para o seu '
                      'saldo. Para remarcar, o prazo é até 3 horas antes. Se '
                      'preferir, você pode remarcar em vez de cancelar.'
                : 'Faltam menos de 24 horas: se cancelar agora, a consulta '
                      'não volta para o seu saldo.'
                      '${canReschedule ? ' Remarcar ainda é possível até 3 horas antes.' : ''}',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6B4A00),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Por que você está cancelando?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v ?? 0),
              child: Column(
                children: [
                  for (var i = 0; i < _reasons.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: PabColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: _reason == i
                                ? PabColors.accent
                                : PabColors.line,
                            width: _reason == i ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: i,
                          activeColor: PabColors.accentText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            _reasons[i],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: PabColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
      footer: [
        FilledButton(
          onPressed: _sending ? null : _confirm,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: PabColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: PabColors.error.withValues(alpha: .6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _sending ? 'Cancelando…' : 'Confirmar cancelamento',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (canReschedule) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _sending ? null : _reschedule,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: PabColors.ink,
              side: const BorderSide(color: PabColors.lineStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Prefiro remarcar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (_error != null) RegError(_error!),
      ],
    );
  }
}
