import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

class CouponListRow extends StatelessWidget {
  final CouponModel coupon;
  final String? ownerName;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onShowRedemptions;

  const CouponListRow({
    super.key,
    required this.coupon,
    this.ownerName,
    required this.onEdit,
    required this.onToggleActive,
    required this.onShowRedemptions,
  });

  String _date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  String get _validity {
    final from = coupon.validFrom;
    final until = coupon.validUntil;
    if (from == null && until == null) return 'Sem prazo';
    if (from == null) return 'Até ${_date(until!)}';
    if (until == null) return 'A partir de ${_date(from)}';
    return '${_date(from)} até ${_date(until)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = coupon.isUsable ? AppColors.success : AppColors.error;
    final usesText = coupon.maxUses == null
        ? '${coupon.uses} usos (sem limite)'
        : '${coupon.uses} de ${coupon.maxUses} usos';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 24,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 20,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: SelectableText(
                          coupon.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextDefault(
                        text: coupon.statusLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ],
                  ),
                  if (coupon.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    TextDefault(
                      text: coupon.description!,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            _Info(
              icon: Icons.campaign_outlined,
              label: 'Titular',
              value: ownerName ?? 'Sem titular',
            ),
            _Info(
              icon: Icons.card_giftcard_outlined,
              label: 'Benefício',
              value: '${coupon.freeDays} dias grátis',
            ),
            _Info(
              icon: Icons.event_outlined,
              label: 'Validade',
              value: _validity,
            ),
            _Info(icon: Icons.people_outline, label: 'Usos', value: usesText),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onShowRedemptions,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Quem usou'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: Icon(
                    coupon.isActive ? Icons.block : Icons.check_circle_outline,
                    color: coupon.isActive
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  onPressed: onToggleActive,
                  tooltip: coupon.isActive ? 'Desativar' : 'Ativar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Info({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextDefault(
                  text: label,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                TextDefault(
                  text: value,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
