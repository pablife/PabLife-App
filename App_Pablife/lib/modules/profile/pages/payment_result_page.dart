import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../dashboard/dashboard_page.dart';
import 'subscription_page.dart' show brl;

/// Resultado do pagamento: aprovado (canvas P4) ou não aprovado (P5).
class PaymentResultPage extends StatelessWidget {
  final bool approved;
  final String planName;
  final int consultations;
  final double amount;
  final String method;
  final DateTime? validUntil;

  /// Motivo da recusa, quando o Mercado Pago informa.
  final String? reason;

  /// Recusado: botão "Pagar com Pix" (só quando o Pix estiver ligado).
  final VoidCallback? onPayWithPix;

  const PaymentResultPage({
    super.key,
    required this.approved,
    required this.planName,
    required this.consultations,
    required this.amount,
    this.method = 'Cartão',
    this.validUntil,
    this.reason,
    this.onPayWithPix,
  });

  static void _goTo(int tab) {
    Get.offAllNamed(DashboardPage.route);
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) =>
      approved ? _approved(context) : _refused(context);

  Widget _approved(BuildContext context) {
    final until = validUntil == null
        ? null
        : DateFormat("d 'de' MMMM", 'pt_BR').format(validUntil!.toLocal());

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: PabColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
        ],
      ),
    );

    return PabCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 40,
              24,
              28,
            ),
            decoration: const BoxDecoration(
              color: PabColors.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: PabColors.accent, width: 4),
                    image: const DecorationImage(
                      image: AssetImage('assets/pages/payment/approved.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pagamento aprovado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: PabColors.onInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Suas consultas já estão disponíveis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: PabColors.navIdle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PabColors.card,
                    border: Border.all(color: PabColors.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      line('Plano', planName),
                      line(
                        'Consultas',
                        consultations == 1
                            ? '1 disponível'
                            : '$consultations disponíveis',
                      ),
                      if (until != null) line('Válidas até', until),
                      line('Valor pago', '${brl(amount)} · $method'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'O recibo fica em Perfil › Minha assinatura › Histórico de '
                  'pagamentos.',
                  style: TextStyle(fontSize: 13, color: PabColors.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegPrimaryButton(
                    label: 'Agendar minha consulta',
                    onTap: () => _goTo(3),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _goTo(0),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: PabColors.accentText,
                    ),
                    child: const Text(
                      'Ir para o Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refused(BuildContext context) {
    const tips = [
      'Conferir número, validade e CVV do cartão.',
      'Tentar outro cartão.',
      'Ver com o banco se a compra online está liberada.',
    ];
    return PabCardFrame(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RegBackButton(onTap: () => Get.back<void>()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCFD6E4),
                          width: 4,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/pages/payment/refused.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pagamento não aprovado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason == null
                        ? 'Nenhum valor foi cobrado. Isso costuma acontecer por '
                              'limite, saldo ou dados do cartão.'
                        : 'Nenhum valor foi cobrado. $reason',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: PabColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        const Text(
                          'O que você pode fazer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        for (final tip in [
                          ...tips,
                          if (onPayWithPix != null)
                            'Pagar com Pix, com aprovação na hora.',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2E4446),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegPrimaryButton(
                    label: 'Tentar novamente',
                    onTap: () => Get.back<void>(),
                  ),
                  if (onPayWithPix != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onPayWithPix,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: PabColors.card,
                        foregroundColor: PabColors.ink,
                        side: const BorderSide(color: PabColors.lineStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Pagar com Pix',
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
    );
  }
}
