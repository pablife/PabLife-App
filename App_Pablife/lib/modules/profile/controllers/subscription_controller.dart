import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../infra/repositories/student_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../widgets/design_system/app_dialog.dart';

import '../../../infra/models/subscription_plan_model.dart';
import '../../../infra/models/subscription_transaction_model.dart';
import '../../../infra/models/user_subscription_model.dart';
import '../../../infra/repositories/payment_repository.dart';
import '../../../infra/repositories/subscription_plan_repository.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/utils/payment_status_messages.dart';
import '../pages/checkout_page.dart';

class SubscriptionController extends GetxController {
  final _planRepository = SubscriptionPlanRepository();
  final _paymentRepository = PaymentRepository();

  List<SubscriptionPlanModel> plans = [];
  String? selectedPlanId;
  String? activePlanId;
  SubscriptionTransactionModel? activeTransaction;
  UserSubscriptionModel? activeSubscription;
  UserSubscriptionModel? pendingSubscription;
  SubscriptionTransactionModel? pendingTransaction;
  String? pendingPaymentMessage;
  bool hasOpenSubscriptionsBlocked = false;
  bool isLoading = false;
  bool isLoadingCancelSubscription = false;

  /// Desconto de estudante (10%): o servidor confere de novo na cobrança.
  StudentStatus studentStatus = StudentStatus.none;
  bool get hasStudentDiscount => studentStatus == StudentStatus.approved;

  static const studentDiscount = 0.10;

  /// Valor cobrado do plano para esta pessoa (mesma conta do servidor).
  double priceOf(SubscriptionPlanModel plan) => hasStudentDiscount
      ? (plan.transactionAmount * (1 - studentDiscount) * 100).round() / 100
      : plan.transactionAmount;

  // Cupom resgatado na tela de planos (P1).
  bool isRedeemingCoupon = false;
  String? redeemedCoupon;
  int? redeemedCouponDays;
  String? couponError;

  static const _couponReasons = {
    'not_found': 'Cupom não encontrado.',
    'inactive': 'Cupom inativo.',
    'not_started': 'Este cupom ainda não está valendo.',
    'expired': 'Cupom expirado.',
    'exhausted': 'Cupom esgotado.',
    'already_used': 'Você já usou este cupom.',
    'not_authenticated': 'Entre na sua conta para usar o cupom.',
  };

  @override
  void onInit() {
    super.onInit();
    _loadActiveSubscription();
    _loadPlans();
    _loadStudentStatus();
  }

  Future<void> _loadStudentStatus() async {
    studentStatus = await StudentRepository().myStatus();
    update();
  }

  /// Resgata o cupom para o plano escolhido: libera por N dias, sem cobrança.
  Future<void> redeemCoupon(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    couponError = null;
    if (code.isEmpty) {
      couponError = 'Digite o código do cupom.';
      update();
      return;
    }
    final planId = selectedPlanId ?? plans.firstOrNull?.id;
    if (planId == null) return;

    isRedeemingCoupon = true;
    update();
    try {
      final response = await _paymentRepository.redeemCoupon(
        code: code,
        planId: planId,
      );
      final data = response.data;
      if (!response.success || data == null) {
        couponError = 'Não foi possível usar o cupom. Tente de novo.';
        return;
      }
      if (data['valid'] != true) {
        couponError = _couponReasons[data['reason']] ?? 'Cupom inválido.';
        return;
      }
      redeemedCoupon = code;
      redeemedCouponDays = (data['free_days'] as num?)?.toInt() ?? 30;
      await AuthService.instance.reloadUserAccessInfo();
      reload();
    } finally {
      isRedeemingCoupon = false;
      update();
    }
  }

  Future<void> _loadActiveSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await _loadSubscriptionsState(user.id);
    } catch (e) {
      debugPrint('Erro ao carregar assinatura ativa: $e');
    }
  }

  Future<void> _loadSubscriptionsState(String userId) async {
    pendingSubscription = null;
    pendingTransaction = null;
    pendingPaymentMessage = null;
    hasOpenSubscriptionsBlocked = false;

    final openSubscriptions = await Supabase.instance.client
        .from('tb_user_subscriptions')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['active', 'pending', 'cancelled'])
        .order('created_at', ascending: false);

    final list = (openSubscriptions as List)
        .map(
          (row) => UserSubscriptionModel.fromMap(row as Map<String, dynamic>),
        )
        .toList();

    activeSubscription = list.firstWhereOrNull(_isSubscriptionActiveNow);
    activePlanId = activeSubscription?.planId;

    // Um Pix gerado e não pago não trava a escolha: gerar outro cancela o
    // anterior (no servidor), e ele expira sozinho em 30 minutos.
    bool isPix(UserSubscriptionModel s) =>
        s.mpPreapprovalId.startsWith('TEMP-PIX-');
    pendingSubscription = list.firstWhereOrNull(
      (subscription) =>
          subscription.status == 'pending' && !isPix(subscription),
    );

    final openCount = list
        .where(
          (s) =>
              s.status != 'cancelled' && !(s.status == 'pending' && isPix(s)),
        )
        .length;
    hasOpenSubscriptionsBlocked = pendingSubscription != null || openCount >= 2;

    if (pendingSubscription != null) {
      pendingTransaction = await _fetchLatestTransaction(
        pendingSubscription!.id,
      );
      if (pendingTransaction != null) {
        pendingPaymentMessage = mapPaymentStatusMessage(
          status: pendingTransaction!.status,
          statusDetail: pendingTransaction!.statusDetail,
        );
      } else {
        pendingPaymentMessage =
            'Pagamento em processamento. Aguarde a confirmação.';
      }
    }

    if (activeSubscription != null) {
      activeTransaction = await _fetchLatestTransaction(activeSubscription!.id);
    }

    update();
  }

  bool _isSubscriptionActiveNow(UserSubscriptionModel subscription) {
    if (subscription.status == 'active') {
      if (!subscription.hasValidPeriod) {
        // Fallback when period dates are missing but status is active.
        return true;
      }
      return subscription.isInPeriod();
    }

    if (subscription.status == 'cancelled') {
      // Cancelled subscriptions are active only within a valid period.
      return subscription.hasValidPeriod && subscription.isInPeriod();
    }

    return false;
  }

  Future<SubscriptionTransactionModel?> _fetchLatestTransaction(
    String subscriptionId,
  ) async {
    final response = await Supabase.instance.client
        .from('tb_subscription_transactions')
        .select()
        .eq('user_subscription_id', subscriptionId)
        .order('mp_date_created', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return SubscriptionTransactionModel.fromMap(response);
  }

  Future<void> _loadPlans() async {
    isLoading = true;
    update();

    try {
      final response = await _planRepository.getAll();

      if (response.success && response.data != null) {
        plans = response.data!.asMap().entries.map((entry) {
          final plan = entry.value;
          final isActive = plan.id == activePlanId && _hasActiveSubscription;

          // Se não há plano ativo, selecionar o primeiro plano por padrão
          final shouldSelect = !_hasActiveSubscription && entry.key == 0;
          if (shouldSelect) {
            selectedPlanId = plan.id;
          }

          return plan.copyWith(
            backgroundColor: _getPlanColor(plan.id, isActive),
            isSelected: shouldSelect || isActive,
          );
        }).toList();
      } else {
        AppSnackbar.to.show('Erro ao carregar planos: ${response.message}');
      }
    } catch (e) {
      debugPrint('Erro ao carregar planos: $e');
      AppSnackbar.to.show('Ocorreu um erro ao carregar os planos');
    } finally {
      isLoading = false;
      update();
    }
  }

  Color _getPlanColor(String planId, bool isActive) {
    if (isActive) {
      return const AppColor(0xFF90EE90); // Verde para plano ativo
    }
    return planId == selectedPlanId
        ? const AppColor(0xFFFF80BD) // Rosa para selecionado
        : const AppColor(0xFFAEBEEC); // Azul para não selecionado
  }

  /// Verifica se a assinatura atual está realmente ativa (não cancelada ou expirada)
  bool get _hasActiveSubscription {
    if (activeSubscription == null) return false;
    return _isSubscriptionActiveNow(activeSubscription!);
  }

  bool get isPaymentProcessingBlocked => hasOpenSubscriptionsBlocked;

  String? get paymentProcessingMessage => pendingPaymentMessage;

  void selectPlan(String planId) {
    // Não permitir selecionar nenhum plano se já houver um ativo e válido
    if (isPaymentProcessingBlocked) {
      AppSnackbar.to.show(
        paymentProcessingMessage ??
            'Pagamento em processamento. Aguarde a confirmação.',
      );
      return;
    }

    if (_hasActiveSubscription && !isSubscriptionCancelled) {
      AppSnackbar.to.show(
        'Você já possui um plano ativo. Cancele-o primeiro para escolher outro plano.',
      );
      return;
    }

    selectedPlanId = planId;
    plans = plans.map((plan) {
      final isActive = plan.id == activePlanId && _hasActiveSubscription;
      final isSelected = plan.id == planId;
      return plan.copyWith(
        isSelected: isSelected || isActive,
        backgroundColor: isActive
            ? const AppColor(0xFF90EE90)
            : (isSelected
                  ? const AppColor(0xFFFF80BD)
                  : const AppColor(0xFFAEBEEC)),
      );
    }).toList();
    update();
  }

  String? getDaysUntilRenewal() {
    if (activeSubscription?.endDate == null) return null;
    final daysUntilRenewal = activeSubscription!.endDate!
        .toUtc()
        .difference(DateTime.now().toUtc())
        .inDays;
    return '$daysUntilRenewal dias';
  }

  /// Verifica se a assinatura foi cancelada pelo usuário
  /// Uma assinatura cancelada continua ativa até a data de renovação
  bool get isSubscriptionCancelled {
    return activeSubscription?.status == 'cancelled';
  }

  void reload() {
    _loadActiveSubscription().then((_) => _loadPlans());
    _loadStudentStatus();
  }

  Future<void> choosePlan() async {
    if (selectedPlanId == null) {
      AppSnackbar.to.show('Por favor, selecione um plano');
      return;
    }

    // Não permitir escolher plano se já houver um ativo e válido
    if (isPaymentProcessingBlocked) {
      AppSnackbar.to.show(
        paymentProcessingMessage ??
            'Pagamento em processamento. Aguarde a confirmação.',
      );
      return;
    }

    if (_hasActiveSubscription && !isSubscriptionCancelled) {
      AppSnackbar.to.show(
        'Você já possui um plano ativo. Cancele-o primeiro para escolher outro plano.',
      );
      return;
    }

    if (activeSubscription?.isInPeriod() == true && Get.context != null) {
      final result = await AppDialog.showConfirmation(
        context: Get.context!,
        title: 'Deseja continuar?',
        message:
            'Sua assinatura está cancelada, mas ainda restam '
            '${getDaysUntilRenewal()} de acesso. O novo plano começa agora.',
        confirmText: 'Continuar',
        cancelText: 'Voltar',
      );
      if (result != true) return;
    }

    isLoading = true;
    update();

    try {
      // Encontrar o plano selecionado na lista
      final selectedPlan = plans.firstWhereOrNull(
        (plan) => plan.id == selectedPlanId,
      );

      if (selectedPlan != null) {
        // Navegar para a página de checkout
        Get.toNamed(CheckoutPage.route, arguments: {'plan': selectedPlan});
      } else {
        AppSnackbar.to.show('Plano não encontrado');
      }
    } catch (e) {
      debugPrint('Erro ao escolher plano: $e');
      AppSnackbar.to.show('Ocorreu um erro ao processar sua solicitação');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> cancelSubscription() async {
    try {
      isLoadingCancelSubscription = true;
      update();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        AppSnackbar.to.show('Usuário não autenticado');
        return;
      }

      if (activeSubscription == null) {
        AppSnackbar.to.show('Nenhuma assinatura ativa encontrada');
        return;
      }

      final response = await _paymentRepository.cancelSubscription();

      if (response.success) {
        AppSnackbar.to.show('Assinatura cancelada com sucesso');
        reload();
      } else {
        AppSnackbar.to.show(
          'Ocorreu um erro ao cancelar a assinatura: ${response.message}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao cancelar assinatura: $e');
      AppSnackbar.to.show('Ocorreu um erro ao cancelar a assinatura');
    } finally {
      isLoadingCancelSubscription = false;
      update();
    }
  }
}
