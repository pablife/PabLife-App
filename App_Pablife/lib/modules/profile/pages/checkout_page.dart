import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../controllers/checkout_controller.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  static const route = '/profile/checkout';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      init: CheckoutController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: const AppBarDefault(title: 'Pagamento'),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 100,
                        left: 20,
                        right: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Preview do Cartão
                          _buildCardPreview(controller),
                          const SizedBox(height: 30),

                          // Número do Cartão
                          _buildTextField(
                            controller: controller.cardNumberController,
                            label: 'Número do Cartão',
                            hint: '0000 0000 0000 0000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                              _CardNumberInputFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Número do cartão é obrigatório';
                              }
                              if (value.replaceAll(' ', '').length < 13) {
                                return 'Número do cartão inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Nome do Titular
                          _buildTextField(
                            controller: controller.cardHolderNameController,
                            label: 'Nome do Titular',
                            hint: 'Nome como está no cartão',
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nome do titular é obrigatório';
                              }
                              if (value.length < 3) {
                                return 'Nome muito curto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // CPF/CNPJ do Titular
                          _buildTextField(
                            controller: controller.cardHolderCpfController,
                            label: 'CPF/CNPJ do Titular',
                            hint: '000.000.000-00 / 00.000.000/0000-00',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(14),
                              CpfOuCnpjFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'CPF/CNPJ do titular é obrigatório';
                              }
                              final digits = value.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digits.length == 11) {
                                if (!UtilBrasilFields.isCPFValido(digits)) {
                                  return 'CPF/CNPJ inválido';
                                }
                                return null;
                              }
                              if (digits.length == 14) {
                                if (!UtilBrasilFields.isCNPJValido(digits)) {
                                  return 'CPF/CNPJ inválido';
                                }
                                return null;
                              }
                              return 'CPF/CNPJ inválido';
                            },
                          ),
                          const SizedBox(height: 16),

                          // Data de Validade
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller:
                                      controller.expirationMonthController,
                                  label: 'Mês',
                                  hint: 'MM',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Obrigatório';
                                    }
                                    final month = int.tryParse(value);
                                    if (month == null ||
                                        month < 1 ||
                                        month > 12) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller:
                                      controller.expirationYearController,
                                  label: 'Ano',
                                  hint: 'AAAA',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Obrigatório';
                                    }
                                    final year = int.tryParse(value);
                                    if (year == null ||
                                        year < DateTime.now().year) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // CVV
                          _buildTextField(
                            controller: controller.securityCodeController,
                            label: 'Código de Segurança (CVV)',
                            hint: '123',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'CVV é obrigatório';
                              }
                              if (value.length < 3) {
                                return 'CVV inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Cupom de desconto
                          _CouponField(controller: controller),
                          const SizedBox(height: 16),

                          // Resumo do Pagamento
                          _buildPaymentSummary(controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botões de Ação
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: EdgeButtonRounded(
                          text: 'Voltar',
                          onTap: () => Get.back(),
                          backgroundColor: const Color(0xFF00343C),
                          side: EdgeSide.right,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EdgeButtonRounded(
                          text: controller.isLoading
                              ? 'Processando...'
                              : 'Pagar',
                          onTap: controller.isLoading
                              ? () {}
                              : () {
                                  FocusScope.of(context).unfocus();
                                  controller.processPayment();
                                },
                          backgroundColor: const Color(0xFF0C8DA1),
                          side: EdgeSide.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.isProcessingPayment)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Pagamento sendo processado...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardPreview(CheckoutController controller) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F71), Color(0xFF0F4C75)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crédito',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              controller.cardBrandDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.maskedCardNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TITULAR',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.displayCardHolderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VÁLIDO ATÉ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.formattedExpirationDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return AppTextFormField(
      controller: controller,
      labelText: label,
      hintText: hint,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildPaymentSummary(CheckoutController controller) {
    final plan = controller.selectedPlan;
    if (plan == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do Pagamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00343C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.reason,
                style: TextStyle(fontSize: 14, color: AppColors.aqua),
              ),
              Text(
                'R\$ ${plan.transactionAmount.toStringAsFixed(2)} por mês',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.aqua,
                ),
              ),
            ],
          ),
          if (controller.hasCoupon) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cupom ${controller.couponCode}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F6E56),
                  ),
                ),
                Text(
                  '${controller.couponFreeDays} dias grátis',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F6E56),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.hasCoupon ? 'Total hoje' : 'Total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.aqua,
                ),
              ),
              Text(
                controller.hasCoupon
                    ? 'R\$ 0.00'
                    : 'R\$ ${plan.transactionAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C8DA1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Campo de cupom: confere o código (validate_coupon) e, se valer, a
// assinatura começa com os dias grátis do cupom, sem cobrança agora.
class _CouponField extends StatefulWidget {
  final CheckoutController controller;

  const _CouponField({required this.controller});

  @override
  State<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<_CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    if (widget.controller.isCheckingCoupon) return;
    widget.controller.applyCoupon(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final checkout = widget.controller;
    if (checkout.hasCoupon) return _buildApplied(checkout);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cupom de desconto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00343C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Color(0xFF00343C)),
                  decoration: InputDecoration(
                    hintText: 'Digite seu cupom',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD0D7F5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD0D7F5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0C8DA1)),
                    ),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0C8DA1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: checkout.isCheckingCoupon
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Aplicar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplied(CheckoutController checkout) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D9E75)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: Color(0xFF0F6E56)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cupom ${checkout.couponCode} aplicado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${checkout.couponFreeDays} dias grátis antes da primeira cobrança',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F6E56),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              checkout.removeCoupon();
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Color(0xFF0F6E56)),
            ),
          ),
        ],
      ),
    );
  }
}

// Formatador para número do cartão
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
