import 'package:flutter/material.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

/// Cartão de número-resumo (ex.: "12 usuários").
class CouponKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color color;

  const CouponKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.color = AppColors.info,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDefault(
                      text: value,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    TextDefault(
                      text: label,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    if (hint != null)
                      TextDefault(
                        text: hint!,
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String percent(double value) => '${(value * 100).toStringAsFixed(0)}%';

String money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
