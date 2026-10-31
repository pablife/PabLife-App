import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/infra/repositories/coupon_repository.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import 'coupon_csv.dart';
import 'widgets/coupon_kpi_card.dart';
import 'widgets/coupon_users_table.dart';

/// Visão do próprio titular (influenciador/parceiro): só os números dele,
/// sem e-mail nem sobrenome dos usuários.
class TitularController extends GetxController {
  final CouponRepository _repository;

  TitularController(this._repository);

  bool loading = false;
  String ownerName = '';
  double commissionPerConversion = 0;
  List<CouponModel> coupons = [];
  List<CouponUserMetric> users = [];

  CouponResults get results => CouponResults.of(users);
  double get commission => results.conversions * commissionPerConversion;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading = true;
    update();
    final owner = await _repository.getMyOwner();
    ownerName = owner.data?['name'] as String? ?? '';
    commissionPerConversion =
        (owner.data?['commission_per_conversion'] as num?)?.toDouble() ?? 0;
    coupons = (await _repository.getMyCoupons()).data ?? [];
    users = (await _repository.getMyUsers()).data ?? [];
    loading = false;
    update();
  }

  Future<void> export() async {
    if (users.isEmpty) {
      Get.snackbar('Aviso', 'Ainda não há usuários para exportar');
      return;
    }
    await exportCouponUsersCsv(
      users,
      'meus_resultados_cupons.csv',
      includeContact: false,
    );
  }
}

class TitularPage extends StatelessWidget {
  const TitularPage({super.key});

  static const route = '/meu-painel';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TitularController>(
      builder: (controller) {
        Get.find<LayoutController>().updateTitle(
          controller.ownerName.isEmpty
              ? 'Meu painel'
              : 'Olá, ${controller.ownerName}',
        );
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = controller.results;

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  CouponKpiCard(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Pessoas que usaram seu cupom',
                    value: '${r.users}',
                  ),
                  CouponKpiCard(
                    icon: Icons.medical_services_outlined,
                    label: 'Fizeram a 1ª consulta',
                    value: '${r.firstConsultations}',
                    hint: percent(r.firstConsultationRate),
                    color: const Color(0xFF9C27B0),
                  ),
                  CouponKpiCard(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Viraram assinantes',
                    value: '${r.conversions}',
                    hint: percent(r.conversionRate),
                    color: AppColors.success,
                  ),
                  if (controller.commissionPerConversion > 0)
                    CouponKpiCard(
                      icon: Icons.payments_outlined,
                      label: 'Sua comissão',
                      value: money(controller.commission),
                      hint:
                          '${money(controller.commissionPerConversion)} por assinante',
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextDefault(
                text: controller.coupons.isEmpty
                    ? 'Você ainda não tem cupons.'
                    : 'Seus cupons: ${controller.coupons.map((c) => '${c.code} (${c.freeDays} dias${c.isActive ? '' : ', inativo'})').join(' · ')}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: TextDefault(
                      text: 'Quem usou seus cupons',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.export,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Exportar para Excel'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CouponUsersTable(
                rows: controller.users,
                showContact: false,
                showOwner: false,
                emptyText: 'Ninguém usou seus cupons ainda.',
              ),
            ],
          ),
        );
      },
    );
  }
}
