import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_dialog.dart';

/// Caixa da justificativa para marcar a consulta como "Cancelada/remarcada".
/// Devolve o texto digitado, ou null se o profissional desistir.
class CancelledRescheduledReasonDialog extends StatefulWidget {
  final String patientName;

  const CancelledRescheduledReasonDialog({
    super.key,
    required this.patientName,
  });

  static Future<String?> show({required String patientName}) {
    return Get.dialog<String>(
      CancelledRescheduledReasonDialog(patientName: patientName),
    );
  }

  @override
  State<CancelledRescheduledReasonDialog> createState() =>
      _CancelledRescheduledReasonDialogState();
}

class _CancelledRescheduledReasonDialogState
    extends State<CancelledRescheduledReasonDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Get.back(result: reason);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return AppDialog(
      title: 'Cancelada/remarcada',
      icon: Icons.event_busy_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escreva a justificativa da consulta com ${widget.patientName}. '
            'O horário volta a ficar livre na agenda.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textAlign: TextAlign.start,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15, color: PabColors.ink),
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: InputDecoration(
              hintText: 'Ex.: paciente pediu para remarcar para outro dia',
              hintStyle: const TextStyle(color: PabColors.muted),
              filled: true,
              fillColor: PabColors.card,
              errorText: _showError ? 'Escreva a justificativa' : null,
              enabledBorder: border(PabColors.lineStrong),
              focusedBorder: border(PabColors.accent, 2),
              errorBorder: border(PabColors.error),
              focusedErrorBorder: border(PabColors.error, 2),
            ),
          ),
        ],
      ),
      cancelText: 'Voltar',
      onCancel: () => Get.back<void>(),
      confirmText: 'Confirmar',
      onConfirm: _confirm,
      destructive: true,
    );
  }
}
