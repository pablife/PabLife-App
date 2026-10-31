import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import 'coupon_owner_detail_page.dart';
import 'coupons_controller.dart';
import 'widgets/coupon_kpi_card.dart';

/// Aba "Titulares": cadastro de influenciadores/parceiros e seus números.
class CouponOwnersPage extends StatelessWidget {
  const CouponOwnersPage({super.key});

  static const route = '/titulares';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Titulares dos cupons');
    return GetBuilder<CouponsController>(
      builder: (controller) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            onPressed: () => controller.openOwnerForm(context),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Novo titular'),
          ),
          body: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : controller.owners.isEmpty
              ? const Center(
                  child: TextDefault(
                    text:
                        'Nenhum titular cadastrado. Clique em "Novo titular".',
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: controller.owners
                      .map(
                        (o) => _OwnerRow(
                          owner: o,
                          coupons: controller
                              .couponsOf(o.id)
                              .map((c) => c.code)
                              .join(', '),
                          results: controller.resultsOfOwner(o.id),
                          commission: controller.commissionOf(o),
                          onOpen: () => Get.toNamed(
                            CouponOwnerDetailPage.route,
                            arguments: o.id,
                          ),
                          onEdit: () => controller.openOwnerForm(context, o),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _OwnerRow extends StatelessWidget {
  final CouponOwnerModel owner;
  final String coupons;
  final CouponResults results;
  final double commission;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _OwnerRow({
    required this.owner,
    required this.coupons,
    required this.results,
    required this.commission,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDefault(
                      text: owner.name,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      text: [
                        owner.kindLabel,
                        if (owner.instagram?.isNotEmpty ?? false)
                          owner.instagram!,
                        if (!owner.isActive) 'Inativo',
                      ].join(' · '),
                      fontSize: 12,
                      color: owner.isActive
                          ? AppColors.textSecondary
                          : AppColors.error,
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      text: 'Comissão: ${owner.commissionLabel}',
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      text: coupons.isEmpty
                          ? 'Sem cupons ainda'
                          : 'Cupons: $coupons',
                      fontSize: 12,
                      color: AppColors.info,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (owner.accessEmail != null)
                      TextDefault(
                        text: 'Acesso ao painel: ${owner.accessEmail}',
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ),
              _Stat(label: 'Usuários', value: '${results.users}'),
              _Stat(
                label: '1ª consulta',
                value:
                    '${results.firstConsultations} (${percent(results.firstConsultationRate)})',
              ),
              _Stat(
                label: 'Assinantes',
                value:
                    '${results.conversions} (${percent(results.conversionRate)})',
              ),
              _Stat(label: 'Comissão', value: money(commission)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Abrir painel'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: onEdit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextDefault(
            text: label,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          TextDefault(text: value, fontSize: 15, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}
