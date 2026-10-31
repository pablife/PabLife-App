import 'package:flutter/material.dart';
import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository extends StrautilsTryThis {
  final _functions = Supabase.instance.client.functions;

  /// Pagamentos de teste (Mercado Pago de teste, nada é cobrado): gerar o app
  /// com `--dart-define=MP_TEST=true`. Sem isso, usa a função oficial.
  static const useTestPayments = bool.fromEnvironment('MP_TEST');

  /// Confere um cupom para o usuário logado, sem usar.
  /// Devolve {valid, reason, free_days, coupon_id}.
  FStrautilsResponse<Map<String, dynamic>> validateCoupon(String code) {
    return tryThis(() async {
      final data = await Supabase.instance.client.rpc(
        'validate_coupon',
        params: {'p_code': code},
      );
      return StrautilsResponse.success(Map<String, dynamic>.from(data as Map));
    }, action: 'conferir cupom');
  }

  /// Usa o cupom: libera o plano pelos dias do cupom, sem cartão e sem
  /// Mercado Pago. Devolve {valid, reason, free_days, ends_at}.
  FStrautilsResponse<Map<String, dynamic>> redeemCoupon({
    required String code,
    required String planId,
  }) {
    return tryThis(() async {
      final data = await Supabase.instance.client.rpc(
        'redeem_coupon',
        params: {'p_code': code, 'p_plan_id': planId},
      );
      return StrautilsResponse.success(Map<String, dynamic>.from(data as Map));
    }, action: 'usar cupom');
  }

  /// Criar assinatura recorrente com cartão de crédito
  /// Utiliza a API de assinaturas do Mercado Pago (/preapproval)
  FStrautilsResponse<Map<String, dynamic>> createSubscription({
    required String planId,
    required Map<String, dynamic> card,
    required String idempotencyKey,
  }) {
    return tryThis(() async {
      if (idempotencyKey.trim().isEmpty) {
        return StrautilsResponse.error('Idempotency key inválida');
      }

      final body = {'plan_id': planId, 'card': card};

      // Nunca registrar os dados do cartão no console.
      debugPrint('Enviando requisição para criar assinatura (plano $planId)');
      final response = await _functions.invoke(
        useTestPayments
            ? 'mercadopago-subscription-test'
            : 'mercadopago-subscription',
        body: body,
        headers: {'X-Idempotency-Key': idempotencyKey},
      );
      debugPrint('Resposta da function: ${response.status}');
      debugPrint('Dados da resposta: ${response.data}');

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        // A função Edge retorna diretamente { subscription: {...}, payment: {...} }
        if (data.containsKey('subscription') || data.containsKey('payment')) {
          return StrautilsResponse.success(
            data,
            message: 'Assinatura criada com sucesso',
          );
        } else {
          return StrautilsResponse.error('Resposta inválida da função');
        }
      } else {
        final data = response.data as Map<String, dynamic>?;
        final errorPayload = data?['error'] as Map<String, dynamic>?;
        final errorMessage =
            errorPayload?['message'] ?? 'Erro de conexão: ${response.status}';
        return StrautilsResponse.error(
          errorMessage,
          data: errorPayload ?? data,
        );
      }
    }, action: 'criar assinatura recorrente');
  }

  FStrautilsResponse<Map<String, dynamic>> cancelSubscription() {
    return tryThis(() async {
      final response = await _functions.invoke(
        'mercadopago-subscription-cancel',
      );
      debugPrint('Resposta do cancelamento: ${response.status}');
      debugPrint('Dados da resposta: ${response.data}');

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final isSuccess = data['success'] == true || data['ok'] == true;
        if (isSuccess) {
          return StrautilsResponse.success(
            (data['data'] as Map<String, dynamic>?) ?? data,
            message: data['message'] ?? 'Assinatura cancelada com sucesso',
          );
        }

        return StrautilsResponse.error(
          data['message'] ?? 'Erro ao cancelar assinatura',
        );
      } else {
        return StrautilsResponse.error('Erro de conexão: ${response.status}');
      }
    }, action: 'cancelar assinatura');
  }
}
