import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/pab_logo.dart';
import '../appointment_details/appointment_details_routes.dart';
import 'appointment_outcome.dart';
import 'professional_area_controller.dart';
import 'professional_dashboard_page.dart' show firstNameAndInitial, hhmm;

/// Histórico do profissional (canvas PH): números gerais, filtros pelos
/// cinco registros e os atendimentos agrupados por mês.
class ProfessionalHistoryPage extends StatefulWidget {
  const ProfessionalHistoryPage({super.key});

  @override
  State<ProfessionalHistoryPage> createState() =>
      _ProfessionalHistoryPageState();
}

enum _Filter {
  all('Todos'),
  done('Realizadas'),
  noShow('Faltas'),
  cancelled('Canceladas'),
  technical('Problema técnico');

  final String label;
  const _Filter(this.label);

  bool matches(AppointmentOutcome o) => switch (this) {
    all => true,
    done => o == AppointmentOutcome.completed,
    noShow => o == AppointmentOutcome.noShow,
    cancelled =>
      o == AppointmentOutcome.cancelledPatient ||
          o == AppointmentOutcome.cancelledProfessional,
    technical => o == AppointmentOutcome.technicalIssue,
  };
}

class _ProfessionalHistoryPageState extends State<ProfessionalHistoryPage> {
  _Filter _filter = _Filter.all;
  String? _open;

  @override
  Widget build(BuildContext context) {
    final controller = ProfessionalAreaController.to;
    return GetBuilder<ProfessionalAreaController>(
      builder: (c) {
        final wide = isWideLayout(context);
        final list = c.history
            .where((a) => _filter.matches(AppointmentOutcome.of(a)!))
            .toList();
        final months = <String, List<ProfessionalAppointmentModel>>{};
        final monthFmt = DateFormat("MMMM 'de' y", 'pt_BR');
        for (final a in list) {
          final key = monthFmt.format(a.startAt.toLocal());
          months.putIfAbsent(key, () => []).add(a);
        }
        final percent = c.attendancePercent;

        return Scaffold(
          backgroundColor: PabColors.background,
          body: RefreshIndicator(
            color: PabColors.accent,
            onRefresh: controller.load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  color: PabColors.ink,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 18,
                    16,
                    18,
                  ),
                  child: _max(
                    wide,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: PabLogo(size: 22),
                          ),
                        const Text(
                          'Histórico',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                        const Text(
                          'Atendimentos realizados',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: _max(
                    wide,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _stat(
                              '${c.completedCount}',
                              'atendimentos\nrealizados',
                            ),
                            const SizedBox(width: 8),
                            _stat(
                              '${c.patientsServed}',
                              'pacientes\natendidos',
                            ),
                            const SizedBox(width: 8),
                            _stat(
                              percent == null ? '—' : '$percent%',
                              'presença',
                              dark: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final f in _Filter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(f.label),
                                    selected: f == _filter,
                                    onSelected: (_) =>
                                        setState(() => _filter = f),
                                    showCheckmark: false,
                                    selectedColor: PabColors.ink,
                                    backgroundColor: PabColors.card,
                                    side: BorderSide(
                                      color: f == _filter
                                          ? PabColors.ink
                                          : PabColors.line,
                                    ),
                                    shape: const StadiumBorder(),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: f == _filter
                                          ? Colors.white
                                          : PabColors.ink,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (c.loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: PabColors.accent,
                              ),
                            ),
                          )
                        else if (list.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: PabColors.card,
                              border: Border.all(color: PabColors.line),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Nenhum atendimento neste filtro.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: PabColors.muted,
                              ),
                            ),
                          ),
                        for (final entry in months.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                            child: Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: PabColors.ink,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: PabColors.card,
                              border: Border.all(color: PabColors.line),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                for (final a in entry.value)
                                  _row(c, a, entry.value.last == a),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _max(bool wide, Widget child) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 760 : double.infinity),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  Widget _stat(String value, String label, {bool dark = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? PabColors.ink : PabColors.card,
          border: dark ? null : Border.all(color: PabColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: dark ? PabColors.onInk : PabColors.accentText,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: dark ? PabColors.onInkSoft : PabColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ProfessionalAreaController c,
    ProfessionalAppointmentModel a,
    bool last,
  ) {
    final outcome = AppointmentOutcome.of(a)!;
    final open = _open == a.id;
    final start = a.startAt.toLocal();
    final when =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} · ${hhmm(start)}';
    final reason = a.cancellationReason?.trim() ?? '';

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = open ? null : a.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstNameAndInitial(a.patientName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      Text(
                        '$when · ${c.sessionNumber(a)}ª sessão',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                OutcomeTag.of(outcome),
                const SizedBox(width: 4),
                Icon(
                  open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: PabColors.muted,
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reason.isEmpty
                      ? 'Atendimento online. A anotação desta sessão fica na '
                            'ficha do paciente.'
                      : 'Justificativa: $reason',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: PabColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed(
                      AppointmentDetailsRoutes.appointmentDetails,
                      arguments: a.id,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PabColors.ink,
                      side: const BorderSide(color: PabColors.lineStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Abrir ficha',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!last) const Divider(height: 1, color: PabColors.line),
      ],
    );
  }
}
