import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/subscription_plan_model.dart';
import '../../../infra/repositories/student_repository.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/subscription_controller.dart';
import 'my_subscription_page.dart';

/// Formata em reais: 292.5 → "R$ 292,50".
String brl(double value) {
  final fixed = value.toStringAsFixed(2).split('.');
  final whole = fixed[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $whole,${fixed[1]}';
}

/// "Planos" (canvas P1): os planos com o preço de cada um (com o desconto de
/// estudante, quando aprovado), o cupom e o botão para seguir ao pagamento.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  static const route = '/profile/subscription';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      initState: (_) => Get.find<SubscriptionController>().reload(),
      builder: (c) {
        final activeOk = c.activePlanId != null && !c.isSubscriptionCancelled;
        final selectedIsActive =
            c.selectedPlanId != null && c.selectedPlanId == c.activePlanId;
        final cta = activeOk
            ? 'Minha assinatura'
            : selectedIsActive && c.isSubscriptionCancelled
            ? 'Reativar plano'
            : 'Escolher plano';

        return PabCardFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: c),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    if (c.isPaymentProcessingBlocked) ...[
                      _Notice(
                        text:
                            c.paymentProcessingMessage ??
                            'Pagamento em processamento. Aguarde a confirmação.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (c.isLoading && c.plans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: PabColors.accent,
                          ),
                        ),
                      ),
                    for (final plan in c.plans) ...[
                      _PlanCard(
                        plan: plan,
                        controller: c,
                        selected:
                            plan.id == c.selectedPlanId ||
                            (activeOk && plan.id == c.activePlanId),
                        active: plan.id == c.activePlanId,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!activeOk) _CouponBox(controller: c),
                    const SizedBox(height: 12),
                    const Text(
                      'As consultas valem até o vencimento do plano. O plano '
                      'renova todo mês no cartão e pode ser cancelado quando '
                      'quiser.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: PabColors.muted,
                      ),
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
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: FilledButton(
                          onPressed: () => Get.back<void>(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 54),
                            backgroundColor: PabColors.ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Voltar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 14,
                        child: RegPrimaryButton(
                          label: cta,
                          loading: c.isLoading && c.plans.isNotEmpty,
                          onTap: activeOk
                              ? () => Get.offNamed(MySubscriptionPage.route)
                              : c.choosePlan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SubscriptionController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final status = controller.studentStatus;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Planos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PabColors.onInk,
            ),
          ),
          if (status == StudentStatus.approved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: PabColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PabColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '−10%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Desconto de estudante ativo em todos os planos.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFFDCE7E6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == StudentStatus.pending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Comprovante de estudante em análise. O desconto aparece aqui '
                'quando for aprovado.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFFFFE2A8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B4A00),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final SubscriptionController controller;
  final bool selected;
  final bool active;

  const _PlanCard({
    required this.plan,
    required this.controller,
    required this.selected,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final discount = c.hasStudentDiscount;
    final consultations = plan.consultations;
    final cancelled = active && c.isSubscriptionCancelled;
    final days = c.activeSubscription?.endDate
        ?.difference(DateTime.now())
        .inDays;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Plano ${plan.reason}',
      child: Material(
        color: selected ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? PabColors.accent : PabColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => c.selectPlan(plan.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipOval(
                          child: AppImage(
                            imageUrl: plan.imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (active)
                          Positioned(
                            left: -6,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: PabColors.ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'PLANO ATIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.reason,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: PabColors.ink,
                            ),
                          ),
                          if (discount)
                            Text(
                              brl(plan.transactionAmount),
                              style: const TextStyle(
                                fontSize: 13,
                                color: PabColors.muted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: PabColors.muted,
                              ),
                            ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: brl(c.priceOf(plan))),
                                const TextSpan(
                                  text: ' /mês',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PabColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PabColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Usar o aplicativo completo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E4446),
                            ),
                          ),
                          Text(
                            consultations == 1
                                ? 'Usar 1 consulta'
                                : 'Usar $consultations consultas',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E4446),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? PabColors.accent : Colors.white,
                        shape: BoxShape.circle,
                        border: selected
                            ? null
                            : Border.all(color: PabColors.lineStrong, width: 2),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
                if (cancelled) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      days == null
                          ? 'Assinatura cancelada'
                          : 'Assinatura cancelada · você ainda tem acesso por '
                                '${days <= 1 ? '1 dia' : '$days dias'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7A1F52),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tem um cupom?": libera o plano escolhido por um período, sem pagamento.
class _CouponBox extends StatefulWidget {
  final SubscriptionController controller;

  const _CouponBox({required this.controller});

  @override
  State<_CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends State<_CouponBox> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final done = c.redeemedCoupon != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: done
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PabColors.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: PabColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Cupom ${c.redeemedCoupon} resgatado\n',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Plano liberado por ${c.redeemedCouponDays} '
                                'dias, sem cobrança.',
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: PabColors.softText,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tem um cupom?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: c.redeemCoupon,
                        style: const TextStyle(
                          fontSize: 15,
                          color: PabColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite o cupom',
                          hintStyle: const TextStyle(color: PabColors.muted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: PabColors.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: PabColors.accent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: c.isRedeemingCoupon
                          ? null
                          : () => c.redeemCoupon(_code.text),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: PabColors.ink,
                        side: const BorderSide(color: PabColors.ink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: c.isRedeemingCoupon
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PabColors.ink,
                              ),
                            )
                          : const Text(
                              'Resgatar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
                if (c.couponError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    c.couponError!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PabColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'O cupom libera o plano escolhido por um período, sem '
                  'pagamento. Não soma com o desconto de estudante.',
                  style: TextStyle(fontSize: 12, color: PabColors.muted),
                ),
              ],
            ),
    );
  }
}
