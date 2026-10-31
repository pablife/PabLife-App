import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import 'coupons_controller.dart';
import 'widgets/coupon_kpi_card.dart';
import 'widgets/coupon_users_table.dart';

/// Aba "Frequência de consultas": quanto quem entrou por cupom usa as
/// consultas (só quantidades e datas, nunca conteúdo clínico).
class CouponConsultationsPage extends StatelessWidget {
  const CouponConsultationsPage({super.key});

  static const route = '/consultas-cupom';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Frequência de consultas');
    return GetBuilder<CouponsController>(
      builder: (controller) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = controller.filteredUsers;
        final results = CouponResults.of(rows);
        final never = rows.where((r) => r.consultations == 0).length;
        final one = rows.where((r) => r.consultations == 1).length;
        final twoToThree = rows
            .where((r) => r.consultations >= 2 && r.consultations <= 3)
            .length;
        final fourPlus = rows.where((r) => r.consultations >= 4).length;
        final ownerCoupons = controller.filterOwnerId == null
            ? controller.coupons
            : controller.couponsOf(controller.filterOwnerId!);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String?>(
                    initialValue: controller.filterOwnerId,
                    decoration: const InputDecoration(labelText: 'Titular'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os titulares'),
                      ),
                      ...controller.owners.map(
                        (o) => DropdownMenuItem<String?>(
                          value: o.id,
                          child: Text(o.name),
                        ),
                      ),
                    ],
                    onChanged: controller.setOwnerFilter,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(controller.filterOwnerId),
                    initialValue: controller.filterCouponId,
                    decoration: const InputDecoration(labelText: 'Cupom'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os cupons'),
                      ),
                      ...ownerCoupons.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.code),
                        ),
                      ),
                    ],
                    onChanged: controller.setCouponFilter,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      controller.exportUsers(rows, 'frequencia_consultas'),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar para Excel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                CouponKpiCard(
                  icon: Icons.functions,
                  label: 'Média de consultas',
                  value: results.averageConsultations.toStringAsFixed(1),
                  hint: '${results.consultations} consultas no total',
                ),
                CouponKpiCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Nunca consultaram',
                  value: '$never',
                  hint: 'Bons para receber lembrete',
                  color: AppColors.error,
                ),
                CouponKpiCard(
                  icon: Icons.looks_one_outlined,
                  label: '1 consulta',
                  value: '$one',
                  color: AppColors.warning,
                ),
                CouponKpiCard(
                  icon: Icons.repeat,
                  label: '2 a 3 consultas',
                  value: '$twoToThree',
                  color: const Color(0xFF9C27B0),
                ),
                CouponKpiCard(
                  icon: Icons.star_outline,
                  label: '4 ou mais',
                  value: '$fourPlus',
                  hint: 'Usuários mais engajados',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CouponUsersTable(
              rows: rows,
              emptyText: 'Nenhum usuário com esses filtros.',
            ),
          ],
        );
      },
    );
  }
}
