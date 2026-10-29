import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/design_system/app_button_default.dart';

import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/subscription_plan_card.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  static const route = '/profile/subscription';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      initState: (_) {
        final controller = Get.find<SubscriptionController>();
        controller.reload();
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: const AppBarDefault(title: 'Planos'),
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
                  child: ListView(
                    padding: const EdgeInsets.only(top: 20, bottom: 100),
                    children: [
                      if (controller.isPaymentProcessingBlocked)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.paymentProcessingMessage ??
                                'Pagamento em processamento. Aguarde a confirmação.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C4E00),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...controller.plans.map((plan) {
                        final isActive = plan.id == controller.activePlanId;
                        return SubscriptionPlanCard(
                          plan: plan,
                          onTap: () => controller.selectPlan(plan.id),
                          isActive: isActive,
                          isCancelled: isActive
                              ? controller.isSubscriptionCancelled
                              : false,
                          daysUntilRenewal:
                              isActive ? controller.getDaysUntilRenewal() : null,
                          onCancelTap: isActive
                              ? () {
                                  controller.cancelSubscription();
                                }
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child:
                      controller.activePlanId != null &&
                          !controller.isSubscriptionCancelled
                      ? // Se há plano ativo, mostrar apenas o botão Voltar centralizado
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: AppButtonDefault(
                              text: 'Voltar',
                              onTap: () => Get.back(),
                              backgroundColor: const Color(0xFF00343C),
                            ),
                          ),
                        )
                      : // Se não há plano ativo, mostrar ambos os botões
                        Row(
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
                                text: 'Escolher Plano',
                                onTap: controller.choosePlan,
                                backgroundColor: const Color(0xFF0C8DA1),
                                side: EdgeSide.left,
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
