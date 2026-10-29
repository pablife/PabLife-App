import 'dart:convert';
import 'package:flutter/material.dart';

class SubscriptionPlanModel {
  final String id;
  final String preapprovalPlanId;
  final String reason;
  final List<String>? features;
  final double transactionAmount;
  final String currencyId;
  final int durationMonths;
  final int consultations;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Propriedades de estado (não vêm do banco)
  final Color backgroundColor;
  final bool isSelected;

  SubscriptionPlanModel({
    required this.id,
    required this.preapprovalPlanId,
    required this.reason,
    this.features,
    required this.transactionAmount,
    required this.currencyId,
    required this.durationMonths,
    required this.consultations,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.backgroundColor,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'preapproval_plan_id': preapprovalPlanId,
      'reason': reason,
      'features': features,
      'transaction_amount': transactionAmount,
      'currency_id': currencyId,
      'duration_months': durationMonths,
      'consultations': consultations,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map, {Color? backgroundColor, bool? isSelected}) {
    return SubscriptionPlanModel(
      id: map['id'] ?? '',
      preapprovalPlanId: map['preapproval_plan_id'] ?? '',
      reason: map['reason'] ?? '',
      features: map['features'] != null
          ? List<String>.from(map['features'] as List)
          : null,
      transactionAmount: map['transaction_amount'] != null
          ? (map['transaction_amount'] is num
              ? map['transaction_amount'].toDouble()
              : double.tryParse(map['transaction_amount'].toString()) ?? 0.0)
          : 0.0,
      currencyId: map['currency_id'] ?? 'BRL',
      durationMonths: map['duration_months'] ?? 0,
      consultations: map['consultations'] ?? 0,
      imagePath: map['image_path'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      backgroundColor: backgroundColor ?? const Color(0xFFAEBEEC),
      isSelected: isSelected ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriptionPlanModel.fromJson(String source) =>
      SubscriptionPlanModel.fromMap(json.decode(source) as Map<String, dynamic>);

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
    DateTime? deletedAt,
    Color? backgroundColor,
    bool? isSelected,
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
      deletedAt: deletedAt ?? this.deletedAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Getters para compatibilidade com código antigo
  double get price => transactionAmount;
  String get name => reason;
}
