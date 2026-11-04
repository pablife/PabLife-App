import 'package:flutter/material.dart';

import '../pages/women_health_flow_page.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

/// Cartão "Saúde da mulher" do planner: abre o modo, troca a trilha ou sai.
class WomenHealthCard extends StatelessWidget {
  final WomenHealthController controller;

  const WomenHealthCard({super.key, required this.controller});

  /// O modo só muda com a confirmação da usuária.
  Future<void> _confirmExit(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do modo Saúde da mulher?'),
        content: const Text(
          'O app volta para as cores normais. Seus registros de humor podem '
          'ficar guardados neste aparelho ou ser apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continuar no modo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('keep'),
            child: const Text('Sair e manter registros'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('erase'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Sair e apagar tudo'),
          ),
        ],
      ),
    );
    if (choice != null) await controller.exit(eraseData: choice == 'erase');
  }

  @override
  Widget build(BuildContext context) {
    final trail = controller.trail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WomenColors.plum,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset('assets/images/app_logo.png', width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saúde da mulher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WomenColors.light,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trail == null
                          ? 'Ciclo, tentativa de gestar, gestação ou menopausa.'
                          : 'Ativo: ${trail.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: WomenColors.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trail == null)
            _button('Começar', WomenHealthFlowPage.open)
          else
            Row(
              children: [
                Expanded(
                  child: _button('Trocar trilha', WomenHealthFlowPage.open),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmExit(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WomenColors.light,
                      side: const BorderSide(
                        color: WomenColors.lilac,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sair do modo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: WomenColors.lilac,
        foregroundColor: WomenColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
