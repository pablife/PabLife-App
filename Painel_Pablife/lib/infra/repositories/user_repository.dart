import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/user_model.dart';

class UserRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<UserModel>> getAllUsers() async {
    return tryThis<List<UserModel>>(
      () async {
        final response = await _client
            .from('tb_users')
            .select()
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((item) => UserModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAllUsers(),
      action: 'buscar usuários',
    );
  }

  FStrautilsResponse<UserModel?> getUserById(String id) async {
    return tryThis<UserModel?>(
      () async {
        final response = await _client
            .from('tb_users')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return StrautilsResponse.success(UserModel.fromMap(response));
        }
        return StrautilsResponse.success(null);
      },
      tryAgain: () => getUserById(id),
      action: 'buscar usuário por ID',
    );
  }

  FStrautilsResponse<bool> updateUserStatus(
    String id,
    UserStatus status,
  ) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_users')
            .update({'status': status.value})
            .eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => updateUserStatus(id, status),
      action: 'atualizar status do usuário',
    );
  }

  FStrautilsResponse<int> getTotalUsers() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_users')
            .select('id')
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getTotalUsers(),
      action: 'contar total de usuários',
    );
  }

  /// Busca todos os usuários com informações de assinatura
  FStrautilsResponse<List<Map<String, dynamic>>>
  getAllUsersWithSubscriptions() async {
    return tryThis<List<Map<String, dynamic>>>(
      () async {
        final response = await _client
            .from('tb_users')
            .select('''
              *,
              tb_user_subscriptions(
                *,
                tb_subscription_plans(*),
                tb_subscription_transactions(*)
              )
            ''')
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> users = [];
        for (final item in response) {
          final subscriptions = item['tb_user_subscriptions'] as List?;
          Map<String, dynamic>? activeSubscription;

          if (subscriptions != null && subscriptions.isNotEmpty) {
            // Buscar assinatura ativa (status 'active')
            final activeSub = subscriptions.firstWhere((sub) {
              return sub['status'] == 'active';
            }, orElse: () => subscriptions.first);
            activeSubscription = activeSub;
          }

          users.add({
            'user': UserModel.fromMap(item),
            'subscription': activeSubscription,
          });
        }

        return StrautilsResponse.success(users);
      },
      tryAgain: () => getAllUsersWithSubscriptions(),
      action: 'buscar usuários com assinaturas',
    );
  }

  /// Busca usuários com paginação (lazy loading)
  /// [offset] - posição inicial
  /// [limit] - quantidade de itens a carregar
  FStrautilsResponse<List<Map<String, dynamic>>>
  getUsersWithSubscriptionsPaginated({
    required int offset,
    int limit = 15,
  }) async {
    return tryThis<List<Map<String, dynamic>>>(
      () async {
        final response = await _client
            .from('tb_users')
            .select('''
              *,
              tb_user_subscriptions(
                *,
                tb_subscription_plans(*),
                tb_subscription_transactions(*)
              )
            ''')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final List<Map<String, dynamic>> users = [];
        for (final item in response) {
          final subscriptions = item['tb_user_subscriptions'] as List?;
          Map<String, dynamic>? activeSubscription;

          if (subscriptions != null && subscriptions.isNotEmpty) {
            final activeSub = subscriptions.firstWhere((sub) {
              return sub['status'] == 'active';
            }, orElse: () => subscriptions.first);
            activeSubscription = activeSub;
          }

          users.add({
            'user': UserModel.fromMap(item),
            'subscription': activeSubscription,
          });
        }

        return StrautilsResponse.success(users);
      },
      tryAgain: () =>
          getUsersWithSubscriptionsPaginated(offset: offset, limit: limit),
      action: 'buscar usuários paginados',
    );
  }

  /// Conta o total de usuários por role
  FStrautilsResponse<int> countUsersByRole(UserRole role) async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_users')
            .select('id')
            .eq('role', role.value)
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => countUsersByRole(role),
      action: 'contar usuários por role',
    );
  }
}
