import 'dart:convert';

class UserSubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String mpPreapprovalId;
  final String? mpPayerId;
  final String? mpPayerEmail;
  final String externalReference;
  final String status;
  final String? reason;
  final int? frequency;
  final String? frequencyType;
  final double? transactionAmount;
  final String? currencyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? mpDateCreated;
  final DateTime? mpLastModified;
  final bool hasFirstPayment;
  final bool hasPreapproval;
  final DateTime? nextPaymentDate;
  final DateTime? startedAt;
  final DateTime? renewedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.mpPreapprovalId,
    this.mpPayerId,
    this.mpPayerEmail,
    required this.externalReference,
    required this.status,
    this.reason,
    this.frequency,
    this.frequencyType,
    this.transactionAmount,
    this.currencyId,
    this.startDate,
    this.endDate,
    this.mpDateCreated,
    this.mpLastModified,
    this.hasFirstPayment = false,
    this.hasPreapproval = false,
    this.nextPaymentDate,
    this.startedAt,
    this.renewedAt,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'mp_preapproval_id': mpPreapprovalId,
      'mp_payer_id': mpPayerId,
      'mp_payer_email': mpPayerEmail,
      'external_reference': externalReference,
      'status': status,
      'reason': reason,
      'frequency': frequency,
      'frequency_type': frequencyType,
      'transaction_amount': transactionAmount,
      'currency_id': currencyId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'mp_date_created': mpDateCreated?.toIso8601String(),
      'mp_last_modified': mpLastModified?.toIso8601String(),
      'has_first_payment': hasFirstPayment,
      'has_preapproval': hasPreapproval,
      'next_payment_date': nextPaymentDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'renewed_at': renewedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserSubscriptionModel.fromMap(Map<String, dynamic> map) {
    return UserSubscriptionModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      planId: map['plan_id'] ?? '',
      mpPreapprovalId: map['mp_preapproval_id'] ?? '',
      mpPayerId: map['mp_payer_id'],
      mpPayerEmail: map['mp_payer_email'],
      externalReference: map['external_reference'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      status: map['status'] ?? '',
      reason: map['reason'],
      frequency: map['frequency'] != null
          ? (map['frequency'] is int
              ? map['frequency']
              : int.tryParse(map['frequency'].toString()))
          : null,
      frequencyType: map['frequency_type'],
      transactionAmount: map['transaction_amount'] != null
          ? (map['transaction_amount'] is num
              ? map['transaction_amount'].toDouble()
              : double.tryParse(map['transaction_amount'].toString()))
          : null,
      currencyId: map['currency_id'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,
      endDate:
          map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      mpDateCreated: map['mp_date_created'] != null
          ? DateTime.parse(map['mp_date_created'])
          : null,
      mpLastModified: map['mp_last_modified'] != null
          ? DateTime.parse(map['mp_last_modified'])
          : null,
      hasFirstPayment: map['has_first_payment'] ?? false,
      hasPreapproval: map['has_preapproval'] ?? false,
      nextPaymentDate: map['next_payment_date'] != null
          ? DateTime.parse(map['next_payment_date'])
          : null,
      startedAt:
          map['started_at'] != null ? DateTime.parse(map['started_at']) : null,
      renewedAt:
          map['renewed_at'] != null ? DateTime.parse(map['renewed_at']) : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSubscriptionModel.fromJson(String source) =>
      UserSubscriptionModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  UserSubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planId,
    String? mpPreapprovalId,
    String? mpPayerId,
    String? mpPayerEmail,
    String? externalReference,
    String? status,
    String? reason,
    int? frequency,
    String? frequencyType,
    double? transactionAmount,
    String? currencyId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? mpDateCreated,
    DateTime? mpLastModified,
    bool? hasFirstPayment,
    bool? hasPreapproval,
    DateTime? nextPaymentDate,
    DateTime? startedAt,
    DateTime? renewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
  }) {
    return UserSubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      mpPreapprovalId: mpPreapprovalId ?? this.mpPreapprovalId,
      mpPayerId: mpPayerId ?? this.mpPayerId,
      mpPayerEmail: mpPayerEmail ?? this.mpPayerEmail,
      externalReference: externalReference ?? this.externalReference,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      frequency: frequency ?? this.frequency,
      frequencyType: frequencyType ?? this.frequencyType,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      currencyId: currencyId ?? this.currencyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mpDateCreated: mpDateCreated ?? this.mpDateCreated,
      mpLastModified: mpLastModified ?? this.mpLastModified,
      hasFirstPayment: hasFirstPayment ?? this.hasFirstPayment,
      hasPreapproval: hasPreapproval ?? this.hasPreapproval,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      startedAt: startedAt ?? this.startedAt,
      renewedAt: renewedAt ?? this.renewedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasValidPeriod => startDate != null && endDate != null;

  bool isInPeriod({DateTime? now}) {
    if (!hasValidPeriod) return false;
    final current = (now ?? DateTime.now()).toUtc();
    final start = startDate!.toUtc();
    final end = endDate!.toUtc();
    return (current.isAtSameMomentAs(start) || current.isAfter(start)) &&
        current.isBefore(end);
  }
}
