import 'dart:convert';

class SubscriptionTransactionModel {
  final String id;
  final String status;
  final String userSubscriptionId;
  final int? mpPaymentId;
  final String? externalReference;
  final String? statusDetail;
  final double? transactionAmount;
  final String? currencyId;
  final int? installments;
  final String? paymentMethodId;
  final String? paymentTypeId;
  final int attemptNo;
  final bool isRetry;
  final String? issuerId;
  final String? mpPayerId;
  final String? mpPayerEmail;
  final DateTime? mpDateCreated;
  final DateTime? mpDateApproved;
  final DateTime? mpDateLastUpdated;
  final double? netReceivedAmount;
  final double? totalPaidAmount;
  final double? refundedAmount;
  final Map<String, dynamic> mpPaymentSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionTransactionModel({
    required this.id,
    required this.status,
    required this.userSubscriptionId,
    this.mpPaymentId,
    this.externalReference,
    this.statusDetail,
    this.transactionAmount,
    this.currencyId,
    this.installments,
    this.paymentMethodId,
    this.paymentTypeId,
    this.attemptNo = 1,
    bool? isRetry,
    this.issuerId,
    this.mpPayerId,
    this.mpPayerEmail,
    this.mpDateCreated,
    this.mpDateApproved,
    this.mpDateLastUpdated,
    this.netReceivedAmount,
    this.totalPaidAmount,
    this.refundedAmount,
    Map<String, dynamic>? mpPaymentSnapshot,
    required this.createdAt,
    required this.updatedAt,
  })  : isRetry = isRetry ?? (attemptNo > 1),
        mpPaymentSnapshot = mpPaymentSnapshot ?? const {};

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'status': status,
      'user_subscription_id': userSubscriptionId,
      'mp_payment_id': mpPaymentId,
      'external_reference': externalReference,
      'status_detail': statusDetail,
      'transaction_amount': transactionAmount,
      'currency_id': currencyId,
      'installments': installments,
      'payment_method_id': paymentMethodId,
      'payment_type_id': paymentTypeId,
      'attempt_no': attemptNo,
      'issuer_id': issuerId,
      'mp_payer_id': mpPayerId,
      'mp_payer_email': mpPayerEmail,
      'mp_date_created': mpDateCreated?.toIso8601String(),
      'mp_date_approved': mpDateApproved?.toIso8601String(),
      'mp_date_last_updated': mpDateLastUpdated?.toIso8601String(),
      'net_received_amount': netReceivedAmount,
      'total_paid_amount': totalPaidAmount,
      'refunded_amount': refundedAmount,
      'mp_payment_snapshot': mpPaymentSnapshot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionTransactionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionTransactionModel(
      id: map['id'] ?? '',
      status: map['status'] ?? 'pending',
      userSubscriptionId: map['user_subscription_id'] ?? '',
      mpPaymentId: map['mp_payment_id'] != null
          ? (map['mp_payment_id'] is int
              ? map['mp_payment_id']
              : int.tryParse(map['mp_payment_id'].toString()))
          : null,
      externalReference: map['external_reference'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      statusDetail: map['status_detail'],
      transactionAmount: map['transaction_amount'] != null
          ? (map['transaction_amount'] is num
              ? map['transaction_amount'].toDouble()
              : double.tryParse(map['transaction_amount'].toString()))
          : null,
      currencyId: map['currency_id'],
      installments: map['installments'] != null
          ? (map['installments'] is int
              ? map['installments']
              : int.tryParse(map['installments'].toString()))
          : null,
      paymentMethodId: map['payment_method_id'],
      paymentTypeId: map['payment_type_id'],
      attemptNo: map['attempt_no'] != null
          ? (map['attempt_no'] is int
              ? map['attempt_no']
              : int.tryParse(map['attempt_no'].toString()) ?? 1)
          : 1,
      isRetry: map['is_retry'] ?? (map['attempt_no'] ?? 1) > 1,
      issuerId: map['issuer_id'],
      mpPayerId: map['mp_payer_id'],
      mpPayerEmail: map['mp_payer_email'],
      mpDateCreated: map['mp_date_created'] != null
          ? DateTime.parse(map['mp_date_created'])
          : null,
      mpDateApproved: map['mp_date_approved'] != null
          ? DateTime.parse(map['mp_date_approved'])
          : null,
      mpDateLastUpdated: map['mp_date_last_updated'] != null
          ? DateTime.parse(map['mp_date_last_updated'])
          : null,
      netReceivedAmount: map['net_received_amount'] != null
          ? (map['net_received_amount'] is num
              ? map['net_received_amount'].toDouble()
              : double.tryParse(map['net_received_amount'].toString()))
          : null,
      totalPaidAmount: map['total_paid_amount'] != null
          ? (map['total_paid_amount'] is num
              ? map['total_paid_amount'].toDouble()
              : double.tryParse(map['total_paid_amount'].toString()))
          : null,
      refundedAmount: map['refunded_amount'] != null
          ? (map['refunded_amount'] is num
              ? map['refunded_amount'].toDouble()
              : double.tryParse(map['refunded_amount'].toString()))
          : null,
      mpPaymentSnapshot: map['mp_payment_snapshot'] is Map<String, dynamic>
          ? map['mp_payment_snapshot'] as Map<String, dynamic>
          : const {},
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriptionTransactionModel.fromJson(String source) =>
      SubscriptionTransactionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  DateTime? get latestPaymentDate {
    final candidates = [
      mpDateLastUpdated,
      mpDateApproved,
      mpDateCreated,
      createdAt,
    ].whereType<DateTime>().toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.compareTo(a));
    return candidates.first;
  }

  SubscriptionTransactionModel copyWith({
    String? id,
    String? status,
    String? userSubscriptionId,
    int? mpPaymentId,
    String? externalReference,
    String? statusDetail,
    double? transactionAmount,
    String? currencyId,
    int? installments,
    String? paymentMethodId,
    String? paymentTypeId,
    int? attemptNo,
    bool? isRetry,
    String? issuerId,
    String? mpPayerId,
    String? mpPayerEmail,
    DateTime? mpDateCreated,
    DateTime? mpDateApproved,
    DateTime? mpDateLastUpdated,
    double? netReceivedAmount,
    double? totalPaidAmount,
    double? refundedAmount,
    Map<String, dynamic>? mpPaymentSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionTransactionModel(
      id: id ?? this.id,
      status: status ?? this.status,
      userSubscriptionId: userSubscriptionId ?? this.userSubscriptionId,
      mpPaymentId: mpPaymentId ?? this.mpPaymentId,
      externalReference: externalReference ?? this.externalReference,
      statusDetail: statusDetail ?? this.statusDetail,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      currencyId: currencyId ?? this.currencyId,
      installments: installments ?? this.installments,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      attemptNo: attemptNo ?? this.attemptNo,
      isRetry: isRetry ?? this.isRetry,
      issuerId: issuerId ?? this.issuerId,
      mpPayerId: mpPayerId ?? this.mpPayerId,
      mpPayerEmail: mpPayerEmail ?? this.mpPayerEmail,
      mpDateCreated: mpDateCreated ?? this.mpDateCreated,
      mpDateApproved: mpDateApproved ?? this.mpDateApproved,
      mpDateLastUpdated: mpDateLastUpdated ?? this.mpDateLastUpdated,
      netReceivedAmount: netReceivedAmount ?? this.netReceivedAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      mpPaymentSnapshot: mpPaymentSnapshot ?? this.mpPaymentSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
