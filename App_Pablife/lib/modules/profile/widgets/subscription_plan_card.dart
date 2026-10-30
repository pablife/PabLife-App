import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/subscription_plan_model.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDisabled;
  final bool isCancelled;
  final String? daysUntilRenewal;
  final VoidCallback? onCancelTap;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.isCancelled = false,
    this.daysUntilRenewal,
    this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: (isActive || isDisabled) ? null : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: plan.backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: isActive
                ? Border.all(color: const Color(0xFF00A86B), width: 3)
                : null,
          ),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppImage(
                            imageUrl: plan.imagePath,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextDefault(
                                  plan.name,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00343C),
                                ),
                                const SizedBox(height: 4),

                                TextDefault(
                                  'Plano R\$${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF00343C),
                                ),
                                const SizedBox(height: 4),

                                // Renderizar features dinamicamente
                                if (plan.features != null &&
                                    plan.features!.isNotEmpty)
                                  ...plan.features!.map(
                                    (feature) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: TextDefault(
                                        feature,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF00343C),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Informações adicionais para plano ativo
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(128),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mostrar status de cancelamento se aplicável
                              if (isCancelled) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF3395,
                                    ).withAlpha(51),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextDefault(
                                    'Assinatura cancelada - Você ainda tem acesso até ${daysUntilRenewal ?? ''} dia(s)',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00343C),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (isCancelled == false &&
                                  daysUntilRenewal != null)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: TextDefault(
                                        isCancelled
                                            ? 'Expira em:'
                                            : 'Próxima renovação em:',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00343C),
                                      ),
                                    ),
                                    TextDefault(
                                      daysUntilRenewal!,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00343C),
                                    ),
                                  ],
                                ),
                              // Mostrar botão de cancelar apenas se não estiver cancelada
                              if (!isCancelled) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButtonDefault(
                                    backgroundColor: const Color(0xFFFF3395),
                                    onTap: onCancelTap,
                                    text: 'Cancelar Assinatura',
                                    isLoading:
                                        Get.find<SubscriptionController>()
                                            .isLoadingCancelSubscription,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00A86B)
                          : (plan.isSelected
                                ? const Color(0xFFFF3395)
                                : const Color(0xFFBFC9E5).withAlpha(102)),
                      shape: BoxShape.circle,
                    ),
                    child: (plan.isSelected || isActive)
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),

                if (isActive)
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A86B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextDefault(
                        'PLANO ATIVO',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
