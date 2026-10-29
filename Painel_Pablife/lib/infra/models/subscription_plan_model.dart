import 'dart:convert';

class SubscriptionPlanModel {
  final String id;
  final String preapprovalPlanId;
  final String reason; // Nome do plano (Lite, Plus, Premium)
  final List<String> features;
  final double transactionAmount;
  final String currencyId;
  final int durationMonths;
  final int consultations;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.preapprovalPlanId,
    required this.reason,
    required this.features,
    required this.transactionAmount,
    required this.currencyId,
    required this.durationMonths,
    required this.consultations,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nome do plano (alias para reason)
  String get name => reason;

  /// Preço formatado
  String get formattedPrice =>
      'R\$ ${transactionAmount.toStringAsFixed(2).replaceAll('.', ',')}';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'preapproval_i': preapprovalPlanId,
      'reason': reason,
      'features': features,
      'transaction_a': transactionAmount,
      'currency_id': currencyId,
      'duration_mon': durationMonths,
      'consultations': consultations,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanModel(
      id: map['id'] ?? '',
      preapprovalPlanId: map['preapproval_i'] ?? '',
      reason: map['reason'] ?? '',
      features: map['features'] != null
          ? List<String>.from(map['features'])
          : <String>[],
      transactionAmount:
          double.tryParse(map['transaction_a'].toString()) ?? 0.0,
      currencyId: map['currency_id'] ?? 'BRL',
      durationMonths: map['duration_mon'] ?? 0,
      consultations: map['consultations'] ?? 0,
      imagePath: map['image_path'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriptionPlanModel.fromJson(String source) =>
      SubscriptionPlanModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  SubscriptionPlanModel copyWith({
    String? id,
    String? preapprovalPlanId,
    String? reason,
    List<String>? features,
    double? transactionAmount,
    String? currencyId,
    int? durationMonths,
    int? consultations,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      preapprovalPlanId: preapprovalPlanId ?? this.preapprovalPlanId,
      reason: reason ?? this.reason,
      features: features ?? this.features,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      currencyId: currencyId ?? this.currencyId,
      durationMonths: durationMonths ?? this.durationMonths,
      consultations: consultations ?? this.consultations,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SubscriptionPlanModel(id: $id, reason: $reason, transactionAmount: $transactionAmount, consultations: $consultations)';
  }
}
