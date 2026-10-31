import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/utils/file_exporter.dart';

/// Planilha (CSV no formato do Excel em português: ";" e acentos) com os
/// usuários que entraram por cupom.
Future<void> exportCouponUsersCsv(
  List<CouponUserMetric> rows,
  String filename, {
  bool includeContact = true,
}) async {
  final date = DateFormat('dd/MM/yyyy');
  String d(DateTime? v) => v == null ? '' : date.format(v);
  String cell(Object? v) {
    final text = (v ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  final header = [
    'Nome',
    if (includeContact) 'E-mail',
    'Titular',
    'Cupom',
    'Plano',
    'Usou em',
    'Acesso grátis até',
    'Situação',
    'Consultas feitas',
    'Faltas',
    'Primeira consulta',
    'Última consulta',
    'Virou assinante em',
    'Mensalidades pagas',
  ];

  final lines = <String>[header.map(cell).join(';')];
  for (final r in rows) {
    lines.add(
      [
        r.fullName,
        if (includeContact) r.email,
        r.ownerName,
        r.couponCode,
        r.planName,
        d(r.redeemedAt),
        d(r.accessUntil),
        r.situation,
        r.consultations,
        r.noShows,
        d(r.firstConsultationAt),
        d(r.lastConsultationAt),
        d(r.convertedAt),
        r.paidPayments,
      ].map(cell).join(';'),
    );
  }

  // BOM para o Excel reconhecer os acentos.
  await saveCsvFile('﻿${lines.join('\r\n')}', filename);
}
