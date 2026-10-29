import 'dart:convert';

/// Status da transação de assinatura
enum SubscriptionTransactionStatus {
  notPay('notPay'),
  active('active'),
  cancelled('cancelled'),
  expired('expired');

  final String value;
  const SubscriptionTransactionStatus(this.value);

  static SubscriptionTransactionStatus fromString(String value) {
    return SubscriptionTransactionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionTransactionStatus.notPay,
    );
  }

  String get displayName {
    switch (this) {
      case SubscriptionTransactionStatus.notPay:
        return 'Não Pago';
      case SubscriptionTransactionStatus.active:
        return 'Ativo';
      case SubscriptionTransactionStatus.cancelled:
        return 'Cancelado';
      case SubscriptionTransactionStatus.expired:
        return 'Expirado';
    }
  }
}

/// Status do pagamento
enum PaymentStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  refunded('refunded');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.approved:
        return 'Aprovado';
      case PaymentStatus.rejected:
        return 'Rejeitado';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }
}

class SubscriptionTransactionModel {
  final String id;
  final String mercadopagoPaymentId;
  final PaymentStatus paymentStatus;
  final SubscriptionTransactionStatus status;
  final bool charged;
  final String? qrCode;
  final String? qrCodeBase64;
  final DateTime qrCodeExpirationDate;
  final DateTime nextPaymentDate;
  final String? paymentMethod;
  final double? servicePrice;
  final String? statusDetail;
  final DateTime startDate;
  final DateTime endDate;
  final String? initPoint;
  final int? billingDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionTransactionModel({
    required this.id,
    required this.mercadopagoPaymentId,
    required this.paymentStatus,
    required this.status,
    required this.charged,
    this.qrCode,
    this.qrCodeBase64,
    required this.qrCodeExpirationDate,
    required this.nextPaymentDate,
    this.paymentMethod,
    this.servicePrice,
    this.statusDetail,
    required this.startDate,
    required this.endDate,
    this.initPoint,
    this.billingDay,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Verifica se a assinatura está ativa
  bool get isActive => status == SubscriptionTransactionStatus.active;

  /// Verifica se o pagamento foi aprovado
  bool get isPaid => paymentStatus == PaymentStatus.approved;

  /// Verifica se a assinatura expirou
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Dias restantes da assinatura
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Preço formatado
  String get formattedPrice => servicePrice != null
      ? 'R\$ ${servicePrice!.toStringAsFixed(2).replaceAll('.', ',')}'
      : '-';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'mercadopago': mercadopagoPaymentId,
      'payment_stai': paymentStatus.value,
      'status': status.value,
      'charged': charged,
      'qr_code': qrCode,
      'qr_code_base': qrCodeBase64,
      'payment_mei': paymentMethod,
      'qr_code_expiration_date': qrCodeExpirationDate.toIso8601String(),
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'service_price': servicePrice,
      'status_detail': statusDetail,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'init_point': initPoint,
      'billing_day': billingDay,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionTransactionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionTransactionModel(
      id: map['id'] ?? '',
      mercadopagoPaymentId: map['mercadopago'] ?? '',
      paymentStatus: PaymentStatus.fromString(
        map['payment_stai'] ?? 'pending',
      ),
      status: SubscriptionTransactionStatus.fromString(
        map['status'] ?? 'notPay',
      ),
      charged: map['charged'] ?? false,
      qrCode: map['qr_code'],
      qrCodeBase64: map['qr_code_base'],
      qrCodeExpirationDate: map['qr_code_expiration_date'] != null
          ? DateTime.parse(map['qr_code_expiration_date'])
          : DateTime.now(),
      nextPaymentDate: map['next_payment_date'] != null
          ? DateTime.parse(map['next_payment_date'])
          : DateTime.now(),
      paymentMethod: map['payment_mei'],
      servicePrice: map['service_price'] != null
          ? double.tryParse(map['service_price'].toString())
          : null,
      statusDetail: map['status_detail'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : DateTime.now(),
      initPoint: map['init_point'],
      billingDay: map['billing_day'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriptionTransactionModel.fromJson(String source) =>
      SubscriptionTransactionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'SubscriptionTransactionModel(id: $id, status: ${status.displayName}, paymentStatus: ${paymentStatus.displayName})';
  }
}
