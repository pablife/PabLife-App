import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionPlanRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<SubscriptionPlanModel?> getById(String id) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_plans')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Plano não encontrado');
      }

      return StrautilsResponse.success(
          SubscriptionPlanModel.fromMap(response));
    }, action: 'buscar plano por ID.');
  }

  FStrautilsResponse<SubscriptionPlanModel?> getByPreapprovalPlanId(
      String preapprovalPlanId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_plans')
          .select()
          .eq('preapproval_plan_id', preapprovalPlanId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Plano não encontrado');
      }

      return StrautilsResponse.success(
          SubscriptionPlanModel.fromMap(response));
    }, action: 'buscar plano por ID de pré-aprovação.');
  }

  FStrautilsResponse<List<SubscriptionPlanModel>> getAll() {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_plans')
          .select()
          .order('transaction_amount', ascending: true); // Ordenar por valor crescente

      final plans = (response as List)
          .map((row) =>
              SubscriptionPlanModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return StrautilsResponse.success(plans);
    }, action: 'buscar todos os planos.');
  }

  FStrautilsResponse<SubscriptionPlanModel> create(
      SubscriptionPlanModel plan) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_plans')
          .insert(plan.toMap())
          .select()
          .single();

      return StrautilsResponse.success(
          SubscriptionPlanModel.fromMap(response));
    }, action: 'criar plano.');
  }

  FStrautilsResponse<SubscriptionPlanModel> update(
      String id, Map<String, dynamic> updates) {
    return tryThis(() async {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('tb_subscription_plans')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return StrautilsResponse.success(
          SubscriptionPlanModel.fromMap(response));
    }, action: 'atualizar plano.');
  }

  FStrautilsResponse<bool> delete(String id) {
    return tryThis(() async {
      await _client.from('tb_subscription_plans').delete().eq('id', id);

      return StrautilsResponse.success(true);
    }, action: 'deletar plano.');
  }
}

