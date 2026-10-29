import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/subscription_plan_model.dart';
import '../models/user_subscription_model.dart';

class SubscriptionRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  /// Busca todos os planos de assinatura
  FStrautilsResponse<List<SubscriptionPlanModel>> getAllPlans() async {
    return tryThis<List<SubscriptionPlanModel>>(
      () async {
        final response = await _client
            .from('tb_subscription_plans')
            .select()
            .order('transaction_amount', ascending: true);

        final plans = (response as List)
            .map((e) => SubscriptionPlanModel.fromMap(e))
            .toList();

        return StrautilsResponse.success(plans);
      },
      tryAgain: () => getAllPlans(),
      action: 'buscar planos de assinatura',
    );
  }

  /// Busca um plano por ID
  FStrautilsResponse<SubscriptionPlanModel?> getPlanById(String planId) async {
    return tryThis<SubscriptionPlanModel?>(
      () async {
        final response = await _client
            .from('tb_subscription_plans')
            .select()
            .eq('id', planId)
            .maybeSingle();

        if (response == null) {
          return StrautilsResponse.success(null);
        }

        return StrautilsResponse.success(
          SubscriptionPlanModel.fromMap(response),
        );
      },
      tryAgain: () => getPlanById(planId),
      action: 'buscar plano por ID',
    );
  }

  FStrautilsResponse<int> getCancelledSubscriptionsCount() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              id,
              tb_subscription_transactions!inner(status)
            ''')
            .eq('tb_subscription_transactions.status', 'cancelled')
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getCancelledSubscriptionsCount(),
      action: 'buscar assinaturas canceladas',
    );
  }

  FStrautilsResponse<Map<String, dynamic>> getSubscriptionsByPlan() async {
    return tryThis<Map<String, dynamic>>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              plan_id,
              tb_subscription_plans!inner(
                id,
                reason
              ),
              tb_subscription_transactions!inner(status)
            ''')
            .eq('tb_subscription_transactions.status', 'active');

        if (response.isEmpty) {
          return StrautilsResponse.success({});
        }

        // Agrupar por plano
        final Map<String, dynamic> planCounts = {};

        for (final sub in response) {
          final plan = sub['tb_subscription_plans'];
          if (plan != null) {
            final planName = plan['reason'] as String;
            planCounts[planName] = (planCounts[planName] ?? 0) + 1;
          }
        }

        return StrautilsResponse.success(planCounts);
      },
      tryAgain: () => getSubscriptionsByPlan(),
      action: 'buscar assinaturas por plano',
    );
  }

  /// Busca total de usuários com assinatura ativa
  FStrautilsResponse<int> getActiveSubscriptionsCount() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              id,
              tb_subscription_transactions!inner(status)
            ''')
            .eq('tb_subscription_transactions.status', 'active')
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getActiveSubscriptionsCount(),
      action: 'buscar assinaturas ativas',
    );
  }

  /// Busca total de usuários em trial (não pago ainda)
  FStrautilsResponse<int> getTrialSubscriptionsCount() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              id,
              tb_subscription_transactions!inner(status)
            ''')
            .eq('tb_subscription_transactions.status', 'notPay')
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getTrialSubscriptionsCount(),
      action: 'buscar assinaturas em trial',
    );
  }

  /// Busca usuários com assinaturas canceladas
  FStrautilsResponse<List<Map<String, dynamic>>>
  getUsersWithCancelledSubscriptions() async {
    return tryThis<List<Map<String, dynamic>>>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              id,
              user_id,
              plan_id,
              tb_users!inner(
                id,
                full_name,
                email,
                phone,
                image_url
              ),
              tb_subscription_plans!inner(
                id,
                reason,
                transaction_amount,
                duration_months
              ),
              tb_subscription_transactions!inner(
                id,
                status,
                start_date,
                end_date,
                updated_at
              )
            ''')
            .eq('tb_subscription_transactions.status', 'cancelled')
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> users = [];
        for (final item in response) {
          final transaction = item['tb_subscription_transactions'];
          users.add({
            'user': item['tb_users'],
            'subscription': {
              'id': item['id'],
              'status': transaction?['status'],
              'cancelled_at': transaction?['updated_at'],
              'start_date': transaction?['start_date'],
              'end_date': transaction?['end_date'],
              'plan': item['tb_subscription_plans'],
            },
          });
        }

        return StrautilsResponse.success(users);
      },
      tryAgain: () => getUsersWithCancelledSubscriptions(),
      action: 'buscar usuários com assinaturas canceladas',
    );
  }

  FStrautilsResponse<Map<String, dynamic>> getAllSubscriptionsByPlan() async {
    return tryThis<Map<String, dynamic>>(
      () async {
        // Primeiro busca todos os planos
        final plansResponse = await _client
            .from('tb_subscription_plans')
            .select('id, reason')
            .order('transaction_amount', ascending: true);

        // Inicializa o mapa com todos os planos com 0
        final Map<String, dynamic> planCounts = {};
        for (final plan in plansResponse) {
          planCounts[plan['reason'] as String] = 0;
        }

        // Busca as assinaturas ativas
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              plan_id,
              tb_subscription_plans!inner(
                id,
                reason
              ),
              tb_subscription_transactions!inner(status)
            ''')
            .inFilter('tb_subscription_transactions.status', [
              'payment_success',
              'active',
              'notPay',
            ]);

        // Conta as assinaturas por plano
        for (final sub in response) {
          final plan = sub['tb_subscription_plans'];
          if (plan != null) {
            final planName = plan['reason'] as String;
            planCounts[planName] = (planCounts[planName] ?? 0) + 1;
          }
        }

        return StrautilsResponse.success(planCounts);
      },
      tryAgain: () => getAllSubscriptionsByPlan(),
      action: 'buscar todas as assinaturas por plano',
    );
  }

  /// Busca assinatura ativa de um usuário
  FStrautilsResponse<UserSubscriptionModel?> getUserActiveSubscription(
    String userId,
  ) async {
    return tryThis<UserSubscriptionModel?>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              *,
              tb_subscription_plans(*),
              tb_subscription_transactions(*)
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) {
          return StrautilsResponse.success(null);
        }

        return StrautilsResponse.success(
          UserSubscriptionModel.fromMap(response),
        );
      },
      tryAgain: () => getUserActiveSubscription(userId),
      action: 'buscar assinatura ativa do usuário',
    );
  }

  /// Busca todas as assinaturas de um usuário
  FStrautilsResponse<List<UserSubscriptionModel>> getUserSubscriptions(
    String userId,
  ) async {
    return tryThis<List<UserSubscriptionModel>>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              *,
              tb_subscription_plans(*),
              tb_subscription_transactions(*)
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final subscriptions = (response as List)
            .map((e) => UserSubscriptionModel.fromMap(e))
            .toList();

        return StrautilsResponse.success(subscriptions);
      },
      tryAgain: () => getUserSubscriptions(userId),
      action: 'buscar assinaturas do usuário',
    );
  }

  /// Busca todas as assinaturas com dados completos
  FStrautilsResponse<List<UserSubscriptionModel>> getAllSubscriptions() async {
    return tryThis<List<UserSubscriptionModel>>(
      () async {
        final response = await _client
            .from('tb_user_subscriptions')
            .select('''
              *,
              tb_subscription_plans(*),
              tb_subscription_transactions(*)
            ''')
            .order('created_at', ascending: false);

        final subscriptions = (response as List)
            .map((e) => UserSubscriptionModel.fromMap(e))
            .toList();

        return StrautilsResponse.success(subscriptions);
      },
      tryAgain: () => getAllSubscriptions(),
      action: 'buscar todas as assinaturas',
    );
  }
}
