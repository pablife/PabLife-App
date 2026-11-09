import 'package:flutter/material.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/pab_colors.dart';
import '../../widgets/design_system/app_dialog.dart';

/// Como foi a consulta: os cinco registros do profissional (canvas PD e PS).
enum AppointmentOutcome {
  completed(
    'completed',
    'Concluída',
    'Consulta concluída',
    'Registrada no histórico como realizada.',
  ),
  noShow(
    'no_show',
    'Paciente faltou',
    'Paciente não compareceu',
    'Registrada como falta. A consulta é descontada do saldo do paciente.',
  ),
  cancelledPatient(
    'cancelled_patient',
    'Cancelada pelo paciente',
    'Cancelada pelo paciente',
    'Registrada como cancelamento do paciente. Se ele avisou com 24 horas '
        'de antecedência, a consulta volta para o saldo.',
  ),
  cancelledProfessional(
    'cancelled_professional',
    'Cancelada por você',
    'Cancelada por mim',
    'A consulta volta para o saldo do paciente, que recebe um aviso para '
        'remarcar.',
  ),
  technicalIssue(
    'technical_issue',
    'Problema técnico',
    'Problema técnico',
    'A consulta volta para o saldo e o paciente recebe um aviso para '
        'escolher um novo horário.',
  );

  final String value;

  /// Rótulo curto (selo no histórico e no Dashboard).
  final String label;

  /// Texto do botão e do título do registro.
  final String action;

  /// O que acontece depois de registrar.
  final String effect;

  const AppointmentOutcome(this.value, this.label, this.action, this.effect);

  (Color, Color) get colors => switch (this) {
    completed => (PabColors.soft, PabColors.softText),
    noShow => (const Color(0xFFFCE8F3), const Color(0xFF7A1F52)),
    cancelledPatient ||
    cancelledProfessional => (const Color(0xFFFFF1D6), const Color(0xFF6B4A00)),
    technicalIssue => (PabColors.lilac, PabColors.lilacText),
  };

  /// Registro de uma consulta já fechada, ou null se ainda está marcada.
  static AppointmentOutcome? of(ProfessionalAppointmentModel a) =>
      switch (a.status) {
        AppointmentStatus.completed => completed,
        AppointmentStatus.noShow => noShow,
        AppointmentStatus.technicalIssue => technicalIssue,
        AppointmentStatus.cancelled =>
          a.cancelledBy == 'patient' ? cancelledPatient : cancelledProfessional,
        _ => null,
      };
}

/// Selo colorido do registro.
class OutcomeTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const OutcomeTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory OutcomeTag.of(AppointmentOutcome outcome) {
    final (bg, fg) = outcome.colors;
    return OutcomeTag(label: outcome.label, background: bg, foreground: fg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

/// Pede a justificativa quando precisa: "Cancelada por mim" com menos de 24 h
/// (obrigatória) e "Problema técnico" (opcional). Devolve null se a pessoa
/// voltou; "" quando não precisa de texto.
Future<String?> askOutcomeReason(
  BuildContext context,
  ProfessionalAppointmentModel appointment,
  AppointmentOutcome outcome,
) async {
  final late24h = DateTime.now().isAfter(
    appointment.startOfScheduledWindow.subtract(const Duration(hours: 24)),
  );
  final required =
      outcome == AppointmentOutcome.cancelledProfessional && late24h;
  final asks = required || outcome == AppointmentOutcome.technicalIssue;

  if (!asks) {
    final ok = await AppDialog.showConfirmation(
      context: context,
      title: outcome.action,
      message: outcome.effect,
      confirmText: 'Registrar',
      cancelText: 'Voltar',
      destructive: outcome == AppointmentOutcome.cancelledProfessional,
      icon: Icons.fact_check_outlined,
    );
    return ok == true ? '' : null;
  }

  final text = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AppDialog(
        title: outcome.action,
        icon: Icons.fact_check_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(outcome.effect),
            const SizedBox(height: 12),
            TextField(
              controller: text,
              maxLines: 3,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: PabColors.ink),
              decoration: InputDecoration(
                hintText: required
                    ? 'Justificativa (obrigatória com menos de 24 h)'
                    : 'O que aconteceu? (opcional)',
                hintStyle: const TextStyle(color: PabColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        confirmText: 'Registrar',
        cancelText: 'Voltar',
        onConfirm: required && text.text.trim().isEmpty
            ? () {}
            : () => Navigator.of(context).pop(text.text.trim()),
        onCancel: () => Navigator.of(context).pop(),
      ),
    ),
  );
  text.dispose();
  return result;
}
