import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/shared/themes/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void onInit() {
    super.onInit();
    _loadActiveSubscription();
    _loadPlans();
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

    pendingSubscription = list.firstWhereOrNull(
      (subscription) => subscription.status == 'pending',
    );

    final openCount = list
        .where((subscription) => subscription.status != 'cancelled')
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
      return const Color(0xFF90EE90); // Verde para plano ativo
    }
    return planId == selectedPlanId
        ? const Color(0xFFFF80BD) // Rosa para selecionado
        : const Color(0xFFAEBEEC); // Azul para não selecionado
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
            ? const Color(0xFF90EE90)
            : (isSelected ? const Color(0xFFFF80BD) : const Color(0xFFAEBEEC)),
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

    if (activeSubscription?.isInPeriod() == true) {
      var result = await Get.dialog(
        AlertDialog(
          title: Text('Deseja continuar?'),
          content: Text(
            'Embora sua assinatura esteja cancelada, ainda restam ${getDaysUntilRenewal()} até o fim do período.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withAlpha(204),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Continuar'),
            ),
          ],
        ),
      );

      if (result != true) {
        return;
      }
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
