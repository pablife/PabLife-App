import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

import 'coupon_kpi_card.dart';

/// Tabela de quem entrou por cupom: situação, consultas e conversão.
class CouponUsersTable extends StatelessWidget {
  final List<CouponUserMetric> rows;
  final bool showContact;
  final bool showOwner;
  final String emptyText;

  /// Percentual do titular: quando informado, mostra a comissão de cada um.
  final double? commissionPercent;

  const CouponUsersTable({
    super.key,
    required this.rows,
    this.showContact = true,
    this.showOwner = true,
    this.commissionPercent,
    this.emptyText = 'Ninguém entrou por cupom ainda.',
  });

  String _date(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yy').format(date);

  Color _situationColor(CouponUserMetric r) {
    if (r.isConverted) return AppColors.success;
    if (r.inFreePeriod) return AppColors.info;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final showCommission = (commissionPercent ?? 0) > 0;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: TextDefault(
            text: emptyText,
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          headingRowHeight: 44,
          columns: [
            const DataColumn(label: Text('Nome')),
            if (showContact) const DataColumn(label: Text('E-mail')),
            if (showOwner) const DataColumn(label: Text('Titular')),
            const DataColumn(label: Text('Cupom')),
            const DataColumn(label: Text('Plano')),
            const DataColumn(label: Text('Entrou em')),
            const DataColumn(label: Text('Situação')),
            const DataColumn(label: Text('Consultas'), numeric: true),
            const DataColumn(label: Text('1ª consulta')),
            const DataColumn(label: Text('Última')),
            const DataColumn(label: Text('Assinou em')),
            const DataColumn(label: Text('Mensalidades'), numeric: true),
            if (showCommission)
              const DataColumn(label: Text('Comissão'), numeric: true),
          ],
          rows: rows.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r.fullName ?? '-')),
                if (showContact) DataCell(SelectableText(r.email ?? '-')),
                if (showOwner) DataCell(Text(r.ownerName ?? 'Sem titular')),
                DataCell(Text(r.couponCode)),
                DataCell(Text(r.planName ?? '-')),
                DataCell(Text(_date(r.redeemedAt))),
                DataCell(
                  TextDefault(
                    text: r.situation,
                    fontWeight: FontWeight.w600,
                    color: _situationColor(r),
                  ),
                ),
                DataCell(
                  Text(
                    r.noShows > 0
                        ? '${r.consultations} (${r.noShows} falta${r.noShows > 1 ? 's' : ''})'
                        : '${r.consultations}',
                  ),
                ),
                DataCell(Text(_date(r.firstConsultationAt))),
                DataCell(Text(_date(r.lastConsultationAt))),
                DataCell(Text(_date(r.convertedAt))),
                DataCell(Text('${r.paidPayments}')),
                if (showCommission)
                  DataCell(
                    Text(
                      r.commissionPayments == 0
                          ? '-'
                          : '${money(r.commissionFor(commissionPercent!))} '
                                '(${r.commissionPayments} mens.)',
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
