import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return AlertDialog(
      title: const Text('Cancelada/remarcada'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: 'Ex.: paciente pediu para remarcar para outro dia',
                border: const OutlineInputBorder(),
                errorText: _showError ? 'Escreva a justificativa' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Voltar')),
        TextButton(
          onPressed: _confirm,
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
