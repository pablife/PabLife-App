import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/user_subscription_model.dart';

class UserSubscriptionRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<UserSubscriptionModel?> getById(String id) {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Assinatura não encontrada');
      }

      return StrautilsResponse.success(
          UserSubscriptionModel.fromMap(response));
    }, action: 'buscar assinatura por ID.');
  }

  FStrautilsResponse<UserSubscriptionModel?> getByUserId(String userId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Assinatura não encontrada');
      }

      return StrautilsResponse.success(
          UserSubscriptionModel.fromMap(response));
    }, action: 'buscar assinatura por ID do usuário.');
  }

  FStrautilsResponse<List<UserSubscriptionModel>> getAllByUserId(
      String userId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final subscriptions = (response as List)
          .map((row) =>
              UserSubscriptionModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return StrautilsResponse.success(subscriptions);
    }, action: 'buscar todas as assinaturas do usuário.');
  }

  FStrautilsResponse<List<UserSubscriptionModel>> getAll() {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .select()
          .order('created_at', ascending: false);

      final subscriptions = (response as List)
          .map((row) =>
              UserSubscriptionModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return StrautilsResponse.success(subscriptions);
    }, action: 'buscar todas as assinaturas.');
  }

  FStrautilsResponse<UserSubscriptionModel> create(
      UserSubscriptionModel subscription) {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .insert(subscription.toMap())
          .select()
          .single();

      return StrautilsResponse.success(
          UserSubscriptionModel.fromMap(response));
    }, action: 'criar assinatura.');
  }

  FStrautilsResponse<UserSubscriptionModel> update(
      String id, Map<String, dynamic> updates) {
    return tryThis(() async {
      final response = await _client
          .from('tb_user_subscriptions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return StrautilsResponse.success(
          UserSubscriptionModel.fromMap(response));
    }, action: 'atualizar assinatura.');
  }

  FStrautilsResponse<bool> delete(String id) {
    return tryThis(() async {
      await _client.from('tb_user_subscriptions').delete().eq('id', id);

      return StrautilsResponse.success(true);
    }, action: 'deletar assinatura.');
  }
}

