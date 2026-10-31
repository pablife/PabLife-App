import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import 'coupons_controller.dart';
import 'widgets/coupon_kpi_card.dart';
import 'widgets/coupon_list_row.dart';
import 'widgets/coupon_redemptions_dialog.dart';

/// Aba "Cupons": criar, editar, ativar/desativar e ver quem usou.
class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  static const route = '/coupons';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Cupons');
    return GetBuilder<CouponsController>(
      builder: (controller) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            onPressed: () => controller.openCouponForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Novo cupom'),
          ),
          body: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          CouponKpiCard(
                            icon: Icons.local_offer_outlined,
                            label: 'Cupons valendo',
                            value:
                                '${controller.usableCoupons} de ${controller.coupons.length}',
                          ),
                          CouponKpiCard(
                            icon: Icons.how_to_reg_outlined,
                            label: 'Usos no total',
                            value: '${controller.totals.users}',
                          ),
                          CouponKpiCard(
                            icon: Icons.timer_outlined,
                            label: 'No período grátis agora',
                            value: '${controller.totals.inFreePeriod}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (controller.coupons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: TextDefault(
                              text:
                                  'Nenhum cupom cadastrado. Clique em "Novo cupom".',
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...controller.coupons.map(
                          (c) => CouponListRow(
                            coupon: c,
                            ownerName: controller.ownerById(c.ownerId)?.name,
                            onEdit: () => controller.openCouponForm(context, c),
                            onToggleActive: () => controller.toggleCoupon(c),
                            onShowRedemptions: () => showDialog<void>(
                              context: context,
                              builder: (_) => CouponRedemptionsDialog(
                                coupon: c,
                                rows: controller.usersOfCoupon(c.id),
                                onExport: () => controller.exportUsers(
                                  controller.usersOfCoupon(c.id),
                                  c.code,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
