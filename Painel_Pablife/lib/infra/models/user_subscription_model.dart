import 'dart:convert';
import 'subscription_plan_model.dart';
import 'subscription_transaction_model.dart';

class UserSubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String status;
  final String? subscriptionTransactionId;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Dados relacionados (preenchidos via join)
  final SubscriptionPlanModel? plan;
  final SubscriptionTransactionModel? transaction;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    this.subscriptionTransactionId,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.plan,
    this.transaction,
  });

  /// Verifica se a assinatura está ativa
  bool get isActive => status == 'active';

  /// Verifica se foi cancelada
  bool get isCancelled => cancelledAt != null;

  /// Data de início (da transação)
  DateTime? get startDate => transaction?.startDate;

  /// Data de término (da transação)
  DateTime? get endDate => transaction?.endDate;

  /// Dias restantes
  int get daysRemaining => transaction?.daysRemaining ?? 0;

  /// Nome do plano
  String get planName => plan?.name ?? 'N/A';

  /// Preço do plano
  String get planPrice => plan?.formattedPrice ?? '-';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'status': status,
      'subscription_transaction_id': subscriptionTransactionId,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserSubscriptionModel.fromMap(Map<String, dynamic> map) {
    return UserSubscriptionModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      planId: map['plan_id'] ?? '',
      status: map['status'] ?? 'active',
      subscriptionTransactionId: map['subscription_transaction_id'] ?? '',
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      plan: map['tb_subscription_plans'] != null
          ? SubscriptionPlanModel.fromMap(map['tb_subscription_plans'])
          : null,
      transaction: map['tb_subscription_transactions'] != null
          ? SubscriptionTransactionModel.fromMap(
              map['tb_subscription_transactions'],
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSubscriptionModel.fromJson(String source) =>
      UserSubscriptionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  UserSubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planId,
    String? status,
    String? subscriptionTransactionId,
    DateTime? cancelledAt,  
    DateTime? createdAt,
    DateTime? updatedAt,
    SubscriptionPlanModel? plan,
    SubscriptionTransactionModel? transaction,
  }) {
    return UserSubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      subscriptionTransactionId:
          subscriptionTransactionId ?? this.subscriptionTransactionId,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      plan: plan ?? this.plan,
      transaction: transaction ?? this.transaction,
    );
  }

  @override
  String toString() {
    return 'UserSubscriptionModel(id: $id, userId: $userId, planName: $planName, status: $status)';
  }
}
