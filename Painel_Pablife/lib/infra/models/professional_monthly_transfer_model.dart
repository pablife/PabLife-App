import 'dart:convert';
import 'package:intl/intl.dart';
import 'user_model.dart';

class ProfessionalMonthlyTransfer {
  final String professionalId;
  final String professionalName;
  final ProfessionalType professionalType;
  final DateTime monthStart;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int appointmentsCount;
  final int distinctUsersCount;
  final double totalTransferAmount;
  final DateTime calculatedAt;

  ProfessionalMonthlyTransfer({
    required this.professionalId,
    required this.professionalName,
    required this.professionalType,
    required this.monthStart,
    required this.periodStart,
    required this.periodEnd,
    required this.appointmentsCount,
    required this.distinctUsersCount,
    required this.totalTransferAmount,
    required this.calculatedAt,
  });

  String get monthLabel => DateFormat('MM/yyyy').format(monthStart);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'professional_id': professionalId,
      'professional_name': professionalName,
      'professional_type': professionalType.value,
      'month_start': monthStart.toIso8601String(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'appointments_count': appointmentsCount,
      'distinct_users_count': distinctUsersCount,
      'total_transfer_amount': totalTransferAmount,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory ProfessionalMonthlyTransfer.fromMap(Map<String, dynamic> map) {
    return ProfessionalMonthlyTransfer(
      professionalId: map['professional_id'] ?? '',
      professionalName: map['professional_name'] ?? '',
      professionalType: ProfessionalType.fromString(
        map['professional_type'] ?? 'nutritionist',
      ),
      monthStart: DateTime.parse(map['month_start']),
      periodStart: DateTime.parse(map['period_start']),
      periodEnd: DateTime.parse(map['period_end']),
      appointmentsCount: (map['appointments_count'] as num?)?.toInt() ?? 0,
      distinctUsersCount: (map['distinct_users_count'] as num?)?.toInt() ?? 0,
      totalTransferAmount:
          double.tryParse(map['total_transfer_amount'].toString()) ?? 0,
      calculatedAt: DateTime.parse(map['calculated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfessionalMonthlyTransfer.fromJson(String source) =>
      ProfessionalMonthlyTransfer.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  ProfessionalMonthlyTransfer copyWith({
    String? professionalId,
    String? professionalName,
    ProfessionalType? professionalType,
    DateTime? monthStart,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? appointmentsCount,
    int? distinctUsersCount,
    double? totalTransferAmount,
    DateTime? calculatedAt,
  }) {
    return ProfessionalMonthlyTransfer(
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalType: professionalType ?? this.professionalType,
      monthStart: monthStart ?? this.monthStart,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      appointmentsCount: appointmentsCount ?? this.appointmentsCount,
      distinctUsersCount: distinctUsersCount ?? this.distinctUsersCount,
      totalTransferAmount: totalTransferAmount ?? this.totalTransferAmount,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }
}
