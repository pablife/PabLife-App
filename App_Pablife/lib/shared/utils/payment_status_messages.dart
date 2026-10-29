String mapPaymentStatusMessage({
  required String status,
  String? statusDetail,
}) {
  final normalizedStatus = status.toLowerCase();
  final detail = statusDetail?.toLowerCase();

  if (detail != null && detail.isNotEmpty) {
    switch (detail) {
      case 'accredited':
        return 'Pagamento aprovado. Sua assinatura será ativada em instantes.';
      case 'partially_refunded':
        return 'Pagamento aprovado com reembolso parcial.';
      case 'pending_capture':
        return 'Pagamento autorizado e aguardando captura.';
      case 'offline_process':
        return 'Pagamento em processamento offline.';
      case 'pending_contingency':
        return 'Estamos processando o pagamento. Em até 2 dias úteis informaremos por e-mail.';
      case 'pending_review_manual':
        return 'Estamos processando seu pagamento. Em até 2 dias úteis informaremos por e-mail ou solicitaremos mais informações.';
      case 'pending_waiting_transfer':
        return 'Aguardando a confirmação da transferência bancária.';
      case 'pending_waiting_payment':
        return 'Aguardando o pagamento.';
      case 'pending_challenge':
        return 'Confirmação pendente do cartão. Conclua o challenge para continuar.';
      case 'bank_error':
        return 'Pagamento rejeitado devido a erro com o banco.';
      case 'cc_rejected_3ds_mandatory':
        return 'Pagamento rejeitado: o desafio 3DS é obrigatório.';
      case 'cc_rejected_bad_filled_card_number':
        return 'Revise o número do cartão.';
      case 'cc_rejected_bad_filled_date':
        return 'Revise a data de vencimento.';
      case 'cc_rejected_bad_filled_other':
        return 'Revise os dados do cartão.';
      case 'cc_rejected_bad_filled_security_code':
        return 'Revise o código de segurança do cartão.';
      case 'cc_rejected_blacklist':
        return 'Não foi possível processar seu pagamento.';
      case 'cc_rejected_call_for_authorize':
        return 'Você deve autorizar o pagamento junto ao emissor do cartão.';
      case 'cc_rejected_card_disabled':
        return 'Cartão desativado. Ligue para a central do seu cartão.';
      case 'cc_rejected_card_error':
        return 'Não conseguimos processar seu pagamento.';
      case 'cc_rejected_duplicated_payment':
        return 'Pagamento duplicado. Use outro cartão ou forma de pagamento.';
      case 'cc_rejected_high_risk':
        return 'Pagamento recusado por alto risco. Use outra forma de pagamento.';
      case 'cc_rejected_insufficient_amount':
        return 'Saldo insuficiente. Use outro cartão.';
      case 'cc_rejected_invalid_installments':
        return 'Número de parcelas inválido para este cartão.';
      case 'cc_rejected_max_attempts':
        return 'Limite de tentativas atingido. Use outro cartão.';
      case 'cc_rejected_other_reason':
        return 'O cartão não processou o pagamento. Use outro cartão.';
      case 'cc_amount_rate_limit_exceeded':
        return 'Pagamento rejeitado por exceder o limite do meio de pagamento.';
      case 'rejected_insufficient_data':
        return 'Pagamento rejeitado por falta de informações obrigatórias.';
      case 'rejected_by_bank':
        return 'Operação recusada pelo banco.';
      case 'rejected_by_regulations':
        return 'Pagamento recusado por regulamentações.';
      case 'insufficient_amount':
        return 'Pagamento rejeitado por valores insuficientes.';
      case 'cc_rejected_card_type_not_allowed':
        return 'Pagamento rejeitado: cartão sem função crédito habilitada.';
    }
  }

  switch (normalizedStatus) {
    case 'approved':
      return 'Pagamento aprovado. Sua assinatura será ativada em instantes.';
    case 'authorized':
      return 'Pagamento autorizado e aguardando captura.';
    case 'in_process':
      return 'Pagamento em processamento.';
    case 'pending':
      return 'Pagamento pendente.';
    case 'rejected':
      return 'Pagamento recusado. Tente novamente.';
    case 'cancelled':
      return 'Pagamento cancelado.';
    case 'charged_back':
      return 'Pagamento estornado (chargeback).';
    case 'refunded':
      return 'Pagamento reembolsado.';
    case 'in_mediation':
      return 'Pagamento em disputa.';
    default:
      return 'Status do pagamento: $normalizedStatus.';
  }
}
