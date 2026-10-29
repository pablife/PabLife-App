import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/subscription_transaction_model.dart';

class SubscriptionTransactionRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<SubscriptionTransactionModel?> getById(String id) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_transactions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Transação não encontrada');
      }

      return StrautilsResponse.success(
          SubscriptionTransactionModel.fromMap(response));
    }, action: 'buscar transação por ID.');
  }

  FStrautilsResponse<SubscriptionTransactionModel?> getByMercadopagoPaymentId(
      int mercadopagoPaymentId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_transactions')
          .select()
          .eq('mp_payment_id', mercadopagoPaymentId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Transação não encontrada');
      }

      return StrautilsResponse.success(
          SubscriptionTransactionModel.fromMap(response));
    }, action: 'buscar transação por ID do MercadoPago.');
  }

  FStrautilsResponse<List<SubscriptionTransactionModel>> getAll({
    String? status,
    String? userSubscriptionId,
    int? mercadopagoPaymentId,
  }) {
    return tryThis(() async {
      var query = _client.from('tb_subscription_transactions').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (userSubscriptionId != null) {
        query = query.eq('user_subscription_id', userSubscriptionId);
      }
      if (mercadopagoPaymentId != null) {
        query = query.eq('mp_payment_id', mercadopagoPaymentId);
      }

      final response = await query.order('created_at', ascending: false);

      final transactions = (response as List)
          .map((row) =>
              SubscriptionTransactionModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return StrautilsResponse.success(transactions);
    }, action: 'buscar todas as transações.');
  }

  FStrautilsResponse<SubscriptionTransactionModel> create(
      SubscriptionTransactionModel transaction) {
    return tryThis(() async {
      final response = await _client
          .from('tb_subscription_transactions')
          .insert(transaction.toMap())
          .select()
          .single();

      return StrautilsResponse.success(
          SubscriptionTransactionModel.fromMap(response));
    }, action: 'criar transação.');
  }

  FStrautilsResponse<SubscriptionTransactionModel> update(
      String id, Map<String, dynamic> updates) {
    return tryThis(() async {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('tb_subscription_transactions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return StrautilsResponse.success(
          SubscriptionTransactionModel.fromMap(response));
    }, action: 'atualizar transação.');
  }

  FStrautilsResponse<bool> delete(String id) {
    return tryThis(() async {
      await _client
          .from('tb_subscription_transactions')
          .delete()
          .eq('id', id);

      return StrautilsResponse.success(true);
    }, action: 'deletar transação.');
  }
}
