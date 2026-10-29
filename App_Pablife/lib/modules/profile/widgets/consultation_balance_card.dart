import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../infra/services/subscription_service.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class ConsultationBalanceCard extends StatelessWidget {
  final List<ConsultationBalance> balances;
  final bool isLoading;
  final String emptyMessage;

  const ConsultationBalanceCard({
    super.key,
    required this.balances,
    required this.isLoading,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    Widget skeletonLine({double width = double.infinity, double height = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(18),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C8DA1).withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available,
                  color: Color(0xFF0C8DA1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? skeletonLine(width: 140, height: 16)
                        : const TextDefault(
                            'Suas consultas',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.aquaText,
                          ),
                    const SizedBox(height: 6),
                    isLoading
                        ? skeletonLine(width: 200, height: 12)
                        : TextDefault(
                            'Disponiveis nas assinaturas ativas',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withAlpha(120),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            ...List.generate(2, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C8DA1).withAlpha(80),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: skeletonLine(width: double.infinity, height: 12),
                    ),
                  ],
                ),
              );
            })
          else if (balances.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C8DA1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: TextDefault(
                      emptyMessage,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.aquaText,
                    ),
                  ),
                ],
              ),
            )
          else
            ...balances.map((balance) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C8DA1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: TextDefault(
                        '${balance.remaining} consultas ate ${dateFormatter.format(balance.expiresAt)}',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.aquaText,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
