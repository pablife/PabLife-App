import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import 'subscription_page.dart' show brl;

/// "Pague com Pix" (canvas P3): QR Code, Pix copia e cola, tempo para pagar
/// e o botão "Já paguei". Fica desligada até a cobrança por Pix existir no
/// servidor (veja `PaymentRepository.pixEnabled`).
class PixPaymentPage extends StatefulWidget {
  final String planLabel;
  final double amount;

  /// QR Code em base64 (PNG), como o Mercado Pago devolve.
  final String qrCodeBase64;

  /// Código "copia e cola".
  final String copyCode;
  final DateTime expiresAt;

  /// Confere se o pagamento caiu. Devolve true quando aprovado.
  final Future<bool> Function() onCheckPaid;

  const PixPaymentPage({
    super.key,
    required this.planLabel,
    required this.amount,
    required this.qrCodeBase64,
    required this.copyCode,
    required this.expiresAt,
    required this.onCheckPaid,
  });

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  Timer? _tick;
  bool _copied = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _remaining {
    final left = widget.expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'Expirado';
    final m = left.inMinutes;
    final s = left.inSeconds % 60;
    return 'Expira em $m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.copyCode));
    setState(() => _copied = true);
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await widget.onCheckPaid();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = widget.expiresAt.isBefore(DateTime.now());
    return PabCardFrame(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  RegBackButton(onTap: () => Get.back<void>()),
                  const SizedBox(width: 12),
                  const Text(
                    'Pague com Pix',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: PabColors.card,
                      border: Border.all(color: PabColors.line),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.planLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: PabColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          brl(widget.amount),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: 'QR Code do Pix',
                          image: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(widget.qrCodeBase64),
                              width: 200,
                              height: 200,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1D6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFF6B4A00),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _remaining,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B4A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pix copia e cola',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: PabColors.card,
                      border: Border.all(color: PabColors.lineStrong),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.copyCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: PabColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _copy,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: PabColors.ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _copied ? 'Copiado' : 'Copiar',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final (i, step) in const [
                    'Abra o app do seu banco e escolha Pix.',
                    'Escaneie o QR Code ou cole o código.',
                    'Confirme o pagamento. A gente avisa aqui na hora.',
                  ].indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${i + 1}. $step',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF2E4446),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: PabColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        expired
                            ? 'O código expirou. Volte e gere outro.'
                            : 'Aguardando pagamento…',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PabColors.accentText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: PabColors.card,
                border: Border(top: BorderSide(color: PabColors.line)),
              ),
              child: RegPrimaryButton(
                label: 'Já paguei',
                loading: _checking,
                onTap: expired ? null : _check,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
