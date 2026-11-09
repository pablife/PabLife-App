import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/checkout_controller.dart';
import 'subscription_page.dart' show brl;

/// "Finalizar compra" (canvas P2): resumo do plano com o desconto de
/// estudante, os dados do cartão e o botão de pagar.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  static const route = '/profile/checkout';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      init: CheckoutController(),
      builder: (c) {
        final plan = c.selectedPlan;
        return PabCardFrame(
          child: SafeArea(
            child: Form(
              key: c.formKey,
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
                          'Finalizar compra',
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
                        if (plan != null) _Summary(controller: c),
                        const SizedBox(height: 14),
                        const Text(
                          'Forma de pagamento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: PabColors.soft,
                            border: Border.all(
                              color: PabColors.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 22,
                                color: PabColors.ink,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Cartão de crédito\n',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Renova todo mês, cancele quando '
                                            'quiser',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: PabColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(color: PabColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CardForm(controller: c),
                        const SizedBox(height: 14),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: PabColors.muted,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pagamento processado com segurança pelo '
                                'Mercado Pago. A Pablife não guarda os dados '
                                'do seu cartão.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: PabColors.muted,
                                ),
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
                      label: 'Pagar ${brl(c.amount)}',
                      loading: c.isProcessingPayment,
                      onTap: plan == null ? null : c.processPayment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  final CheckoutController controller;

  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final plan = c.selectedPlan!;
    final full = plan.transactionAmount;
    final total = c.amount;
    final consultations = plan.consultations;

    Widget line(String label, String value, {Color? color, bool bold = false}) {
      final style = TextStyle(
        fontSize: bold ? 17 : 14,
        fontWeight: bold
            ? FontWeight.w800
            : color != null
            ? FontWeight.w700
            : FontWeight.w500,
        color: color ?? PabColors.ink,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: style.copyWith(
                  color: color ?? (bold ? PabColors.ink : PabColors.muted),
                ),
              ),
            ),
            Text(value, style: style),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppImage(
                  imageUrl: plan.imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plano ${plan.reason}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    Text(
                      consultations == 1
                          ? 'App completo + 1 consulta'
                          : 'App completo + $consultations consultas',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Get.back<void>(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: PabColors.accentText,
                ),
                child: const Text(
                  'Trocar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: PabColors.line),
          const SizedBox(height: 4),
          line('Plano ${plan.reason}', brl(full)),
          if (c.hasStudentDiscount)
            line(
              'Desconto estudante (10%)',
              '− ${brl(full - total)}',
              color: PabColors.accentText,
            ),
          const SizedBox(height: 4),
          line('Total por mês', brl(total), bold: true),
        ],
      ),
    );
  }
}

class _CardForm extends StatelessWidget {
  final CheckoutController controller;

  const _CardForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardField(
            label: 'Número do cartão',
            hint: '0000 0000 0000 0000',
            controller: c.cardNumberController,
            keyboardType: TextInputType.number,
            autofill: const [AutofillHints.creditCardNumber],
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberInputFormatter(),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Digite o número do cartão.';
              if (v.replaceAll(' ', '').length < 13) {
                return 'Número do cartão inválido.';
              }
              return null;
            },
          ),
          _CardField(
            label: 'Nome no cartão',
            hint: 'Como está impresso',
            controller: c.cardHolderNameController,
            capitalization: TextCapitalization.characters,
            autofill: const [AutofillHints.creditCardName],
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'Digite o nome como está no cartão.';
              }
              return null;
            },
          ),
          _CardField(
            label: 'CPF ou CNPJ do titular',
            hint: '000.000.000-00',
            controller: c.cardHolderCpfController,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
              CpfOuCnpjFormatter(),
            ],
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.isEmpty) return 'Digite o CPF ou CNPJ do titular.';
              final ok = digits.length == 11
                  ? UtilBrasilFields.isCPFValido(digits)
                  : digits.length == 14 &&
                        UtilBrasilFields.isCNPJValido(digits);
              return ok ? null : 'CPF ou CNPJ inválido.';
            },
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardField(
                  label: 'Mês',
                  hint: 'MM',
                  controller: c.expirationMonthController,
                  keyboardType: TextInputType.number,
                  autofill: const [AutofillHints.creditCardExpirationMonth],
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (v) {
                    final m = int.tryParse(v ?? '');
                    return m == null || m < 1 || m > 12 ? 'Inválido' : null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardField(
                  label: 'Ano',
                  hint: 'AAAA',
                  controller: c.expirationYearController,
                  keyboardType: TextInputType.number,
                  autofill: const [AutofillHints.creditCardExpirationYear],
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    final y = int.tryParse(v ?? '');
                    return y == null || y < DateTime.now().year
                        ? 'Inválido'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardField(
                  label: 'CVV',
                  hint: '123',
                  controller: c.securityCodeController,
                  keyboardType: TextInputType.number,
                  obscure: true,
                  autofill: const [AutofillHints.creditCardSecurityCode],
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) => (v ?? '').length < 3 ? 'Inválido' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> formatters;
  final List<String> autofill;
  final TextCapitalization capitalization;
  final bool obscure;
  final String? Function(String?) validator;

  const _CardField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.formatters = const [],
    this.autofill = const [],
    this.capitalization = TextCapitalization.none,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            autofillHints: autofill,
            textCapitalization: capitalization,
            obscureText: obscure,
            validator: validator,
            style: const TextStyle(fontSize: 15, color: PabColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: PabColors.muted),
              isDense: true,
              filled: true,
              fillColor: PabColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
              enabledBorder: border(PabColors.lineStrong),
              focusedBorder: border(PabColors.accent, 2),
              errorBorder: border(PabColors.error),
              focusedErrorBorder: border(PabColors.error, 2),
              errorStyle: const TextStyle(color: PabColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Número do cartão em grupos de quatro.
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
