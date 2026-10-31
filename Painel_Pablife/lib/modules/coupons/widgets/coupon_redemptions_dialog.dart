import 'package:flutter/material.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';

import 'coupon_users_table.dart';

/// Quem usou um cupom, com consultas e conversão; exporta para Excel.
class CouponRedemptionsDialog extends StatelessWidget {
  final CouponModel coupon;
  final List<CouponUserMetric> rows;
  final VoidCallback onExport;

  const CouponRedemptionsDialog({
    super.key,
    required this.coupon,
    required this.rows,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quem usou o cupom ${coupon.code}'),
      content: SizedBox(
        width: 1000,
        height: 480,
        child: SingleChildScrollView(
          child: CouponUsersTable(
            rows: rows,
            showOwner: false,
            emptyText: 'Ninguém usou este cupom ainda.',
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar para Excel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
