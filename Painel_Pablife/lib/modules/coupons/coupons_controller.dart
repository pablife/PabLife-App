import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/infra/repositories/coupon_repository.dart';

import 'coupon_csv.dart';
import 'widgets/coupon_form_dialog.dart';
import 'widgets/coupon_owner_form_dialog.dart';

/// Dados de todas as abas de cupons: cupons, titulares e os resultados de
/// quem entrou por cupom (primeira consulta e conversão em assinante).
class CouponsController extends GetxController {
  final CouponRepository _repository;

  CouponsController(this._repository);

  bool loading = false;
  List<CouponModel> coupons = <CouponModel>[];
  List<CouponOwnerModel> owners = <CouponOwnerModel>[];
  List<CouponUserMetric> users = <CouponUserMetric>[];

  // Filtros da aba de consultas.
  String? filterOwnerId;
  String? filterCouponId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading = true;
    update();
    final results = await Future.wait([
      _repository.getCoupons(),
      _repository.getOwners(),
      _repository.getUserMetrics(),
    ]);
    final rawCoupons = (results[0].data as List<CouponModel>?) ?? [];
    owners = (results[1].data as List<CouponOwnerModel>?) ?? [];
    users = (results[2].data as List<CouponUserMetric>?) ?? [];

    coupons = rawCoupons.map((c) {
      final rows = users.where((u) => u.couponId == c.id);
      return c.copyWith(
        uses: rows.length,
        activeNow: rows.where((u) => u.inFreePeriod).length,
      );
    }).toList();

    loading = false;
    update();
  }

  // ---------- Consultas sobre os dados ----------

  CouponOwnerModel? ownerById(String? id) =>
      id == null ? null : owners.firstWhereOrNull((o) => o.id == id);

  List<CouponModel> couponsOf(String ownerId) =>
      coupons.where((c) => c.ownerId == ownerId).toList();

  List<CouponUserMetric> usersOfOwner(String ownerId) =>
      users.where((u) => u.ownerId == ownerId).toList();

  List<CouponUserMetric> usersOfCoupon(String couponId) =>
      users.where((u) => u.couponId == couponId).toList();

  CouponResults get totals => CouponResults.of(users);

  CouponResults resultsOfOwner(String ownerId) =>
      CouponResults.of(usersOfOwner(ownerId));

  double commissionOf(CouponOwnerModel owner) =>
      resultsOfOwner(owner.id).conversions * owner.commissionPerConversion;

  double get totalCommission =>
      owners.fold(0, (sum, o) => sum + commissionOf(o));

  int get usableCoupons => coupons.where((c) => c.isUsable).length;

  /// Titulares do que mais trouxe usuários para o que menos trouxe.
  List<(CouponOwnerModel, CouponResults)> get ownerRanking {
    final list = owners.map((o) => (o, resultsOfOwner(o.id))).toList();
    list.sort((a, b) => b.$2.users.compareTo(a.$2.users));
    return list;
  }

  static const _months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  /// Usos, primeiras consultas e conversões dos últimos [months] meses.
  List<MonthlyCouponResult> monthly([int months = 6]) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final start = DateTime(now.year, now.month - (months - 1 - i));
      final end = DateTime(start.year, start.month + 1);
      bool inMonth(DateTime? d) =>
          d != null && !d.isBefore(start) && d.isBefore(end);
      return MonthlyCouponResult(
        label: '${_months[start.month - 1]}/${start.year % 100}',
        uses: users.where((u) => inMonth(u.redeemedAt)).length,
        firstConsultations: users
            .where((u) => inMonth(u.firstConsultationAt))
            .length,
        conversions: users.where((u) => inMonth(u.convertedAt)).length,
      );
    });
  }

  /// Usuários da aba de consultas (com filtros), quem consulta mais primeiro.
  List<CouponUserMetric> get filteredUsers {
    final list = users.where((u) {
      if (filterOwnerId != null && u.ownerId != filterOwnerId) return false;
      if (filterCouponId != null && u.couponId != filterCouponId) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => b.consultations.compareTo(a.consultations));
    return list;
  }

  void setOwnerFilter(String? ownerId) {
    filterOwnerId = ownerId;
    if (filterCouponId != null &&
        ownerId != null &&
        coupons.firstWhereOrNull((c) => c.id == filterCouponId)?.ownerId !=
            ownerId) {
      filterCouponId = null;
    }
    update();
  }

  void setCouponFilter(String? couponId) {
    filterCouponId = couponId;
    update();
  }

  // ---------- Ações ----------

  Future<void> openCouponForm(
    BuildContext context, [
    CouponModel? editing,
  ]) async {
    final result = await showDialog<CouponModel>(
      context: context,
      builder: (_) => CouponFormDialog(editing: editing, owners: owners),
    );
    if (result == null) return;

    final response = await _repository.saveCoupon(result);
    if (response.success && response.data == true) {
      Get.snackbar(
        'Pronto',
        editing == null ? 'Cupom criado' : 'Cupom atualizado',
      );
      await load();
    } else {
      final duplicated =
          response.message.contains('23505') ||
          response.message.toLowerCase().contains('duplicate');
      Get.snackbar(
        'Aviso',
        duplicated
            ? 'Já existe um cupom com o código ${result.code}'
            : 'Não foi possível salvar o cupom',
      );
    }
  }

  Future<void> toggleCoupon(CouponModel coupon) async {
    final response = await _repository.saveCoupon(
      coupon.copyWith(isActive: !coupon.isActive),
    );
    if (response.success && response.data == true) {
      await load();
    } else {
      Get.snackbar('Aviso', 'Falha ao alterar status do cupom');
    }
  }

  Future<void> openOwnerForm(
    BuildContext context, [
    CouponOwnerModel? editing,
  ]) async {
    final result = await showDialog<(CouponOwnerModel, String)>(
      context: context,
      builder: (_) => CouponOwnerFormDialog(editing: editing),
    );
    if (result == null) return;
    var (owner, accessEmail) = result;

    // Conta com que o titular entra no painel (precisa ter cadastro no app).
    if (accessEmail.isEmpty) {
      owner = owner.copyWith(clearAccess: true);
    } else if (accessEmail.toLowerCase() !=
        (editing?.accessEmail ?? '').toLowerCase()) {
      final found = await _repository.findUserIdByEmail(accessEmail);
      if (!found.success || found.data == null) {
        Get.snackbar(
          'Aviso',
          'Não há cadastro no app com o e-mail $accessEmail. '
              'O titular precisa criar a conta no app primeiro.',
        );
        return;
      }
      owner = owner.copyWith(accessUserId: found.data);
    }

    final response = await _repository.saveOwner(owner);
    if (response.success && response.data == true) {
      Get.snackbar(
        'Pronto',
        editing == null ? 'Titular cadastrado' : 'Titular atualizado',
      );
      await load();
    } else {
      final duplicated =
          response.message.contains('23505') ||
          response.message.toLowerCase().contains('duplicate');
      Get.snackbar(
        'Aviso',
        duplicated
            ? 'Essa conta de acesso já está ligada a outro titular'
            : 'Não foi possível salvar o titular',
      );
    }
  }

  Future<void> exportUsers(List<CouponUserMetric> rows, String name) async {
    if (rows.isEmpty) {
      Get.snackbar('Aviso', 'Não há usuários para exportar');
      return;
    }
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await exportCouponUsersCsv(rows, 'cupons_${name}_$stamp.csv');
  }
}

class MonthlyCouponResult {
  final String label;
  final int uses;
  final int firstConsultations;
  final int conversions;

  const MonthlyCouponResult({
    required this.label,
    required this.uses,
    required this.firstConsultations,
    required this.conversions,
  });
}
