import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import 'coupon_owners_page.dart';
import 'coupons_controller.dart';
import 'widgets/coupon_kpi_card.dart';
import 'widgets/coupon_users_table.dart';

/// Painel de um titular: números, cupons e os usuários que ele trouxe.
class CouponOwnerDetailPage extends StatelessWidget {
  const CouponOwnerDetailPage({super.key});

  static const route = '/titulares/painel';

  @override
  Widget build(BuildContext context) {
    final ownerId = Get.arguments as String?;
    return GetBuilder<CouponsController>(
      builder: (controller) {
        final owner = controller.ownerById(ownerId);
        Get.find<LayoutController>().updateTitle(
          owner == null ? 'Painel do titular' : 'Painel de ${owner.name}',
        );
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (owner == null) {
          return Center(
            child: TextButton(
              onPressed: () => Get.offNamed(CouponOwnersPage.route),
              child: const Text('Titular não encontrado. Voltar à lista'),
            ),
          );
        }

        final rows = controller.usersOfOwner(owner.id);
        final results = controller.resultsOfOwner(owner.id);
        final coupons = controller.couponsOf(owner.id);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Get.offNamed(CouponOwnersPage.route),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Titulares'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => controller.exportUsers(
                    rows,
                    owner.name.toLowerCase().replaceAll(' ', '_'),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar para Excel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                CouponKpiCard(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Usuários trazidos',
                  value: '${results.users}',
                  hint: '${results.inFreePeriod} no período grátis',
                ),
                CouponKpiCard(
                  icon: Icons.medical_services_outlined,
                  label: 'Fizeram a 1ª consulta',
                  value: '${results.firstConsultations}',
                  hint: percent(results.firstConsultationRate),
                  color: const Color(0xFF9C27B0),
                ),
                CouponKpiCard(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Viraram assinantes',
                  value: '${results.conversions}',
                  hint: '${percent(results.conversionRate)} de conversão',
                  color: AppColors.success,
                ),
                CouponKpiCard(
                  icon: Icons.payments_outlined,
                  label: 'Comissão',
                  value: money(controller.commissionOf(owner)),
                  hint: '${money(owner.commissionPerConversion)} por assinante',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextDefault(
              text: coupons.isEmpty
                  ? 'Este titular ainda não tem cupons. Ligue um cupom a ele na aba "Cupons".'
                  : 'Cupons: ${coupons.map((c) => '${c.code} (${c.statusLabel.toLowerCase()})').join(' · ')}',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const TextDefault(
              text: 'Usuários que entraram pelos cupons dele',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            CouponUsersTable(
              rows: rows,
              showOwner: false,
              emptyText: 'Ninguém entrou pelos cupons deste titular ainda.',
            ),
          ],
        );
      },
    );
  }
}
