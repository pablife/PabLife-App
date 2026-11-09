import 'package:flutter/material.dart';

import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../widgets/design_system/app_dialog.dart';
import '../auth/pages/widgets/registration_layout.dart';
import 'agenda_service.dart';

/// "Semana padrão" (canvas PA): em quais dias e períodos o profissional
/// atende toda semana. Salvar cria os horários que faltam e encerra, a
/// partir de agora, os que saíram (consultas já marcadas continuam).
class WeekPatternSheet extends StatefulWidget {
  final String professionalId;
  final AgendaService service;

  const WeekPatternSheet({
    super.key,
    required this.professionalId,
    required this.service,
  });

  /// Abre a janela e devolve true se mudou alguma coisa.
  static Future<bool> open(
    BuildContext context, {
    required String professionalId,
    required AgendaService service,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PabColors.background,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          WeekPatternSheet(professionalId: professionalId, service: service),
    );
    return changed ?? false;
  }

  @override
  State<WeekPatternSheet> createState() => _WeekPatternSheetState();
}

class _WeekPatternSheetState extends State<WeekPatternSheet> {
  static const _days = [1, 2, 3, 4, 5, 6, 0];
  static const _names = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  WeekPattern _current = {};
  final Map<int, Set<String>> _desired = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pattern = await widget.service.weekPattern(widget.professionalId);
    if (!mounted) return;
    setState(() {
      _current = pattern;
      _desired
        ..clear()
        ..addAll({
          for (final e in pattern.entries) e.key: e.value.keys.toSet(),
        });
      _loading = false;
    });
  }

  Set<String> _hoursOf(WeekPeriod p) =>
      p.hours.map((h) => AgendaService.hhmm(h)).toSet();

  /// 2 = período inteiro, 1 = em parte, 0 = fora.
  int _state(int day, WeekPeriod p) {
    final set = _desired[day] ?? const {};
    final hours = _hoursOf(p);
    final n = hours.where(set.contains).length;
    return n == hours.length
        ? 2
        : n > 0
        ? 1
        : 0;
  }

  void _toggle(int day, WeekPeriod p) {
    final set = _desired.putIfAbsent(day, () => {});
    final hours = _hoursOf(p);
    setState(() {
      if (_state(day, p) == 2) {
        set.removeAll(hours);
      } else {
        set.addAll(hours);
      }
    });
  }

  (int, int) get _diff {
    var add = 0;
    var remove = 0;
    for (final day in _days) {
      final now = _current[day]?.keys.toSet() ?? <String>{};
      final want = _desired[day] ?? <String>{};
      add += want.difference(now).length;
      remove += now.difference(want).length;
    }
    return (add, remove);
  }

  Future<void> _save() async {
    final (add, remove) = _diff;
    if (add == 0 && remove == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    final parts = [
      if (add > 0) 'abrir $add ${add == 1 ? 'horário' : 'horários'} por semana',
      if (remove > 0)
        'encerrar $remove ${remove == 1 ? 'horário' : 'horários'} a partir de agora',
    ];
    final ok = await AppDialog.showConfirmation(
      context: context,
      title: 'Salvar semana padrão?',
      message:
          'Vamos ${parts.join(' e ')}. Consultas já marcadas continuam '
          'valendo.',
      confirmText: 'Salvar',
      cancelText: 'Voltar',
      icon: Icons.event_repeat_rounded,
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    final errors = await widget.service.saveWeekPattern(
      professionalId: widget.professionalId,
      current: _current,
      desired: _desired,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (errors.isEmpty) {
      AppSnackbar.to.show('Semana padrão salva.');
      Navigator.of(context).pop(true);
    } else {
      AppSnackbar.to.show('Parte da semana não foi salva: ${errors.first}');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: PabColors.accent),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Semana padrão',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Marque os períodos em que você atende toda semana. '
                    'Sessões online de 50 min, uma por hora.',
                    style: TextStyle(fontSize: 13, color: PabColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [for (final day in _days) _dayRow(day)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RegPrimaryButton(
                    label: 'Salvar semana',
                    loading: _saving,
                    onTap: _save,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _dayRow(int day) {
    final custom =
        (_desired[day] ?? const <String>{})
            .where(
              (t) => !WeekPeriod.values.any((p) => _hoursOf(p).contains(t)),
            )
            .toList()
          ..sort();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _names[day],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in WeekPeriod.values) _periodChip(day, p),
                for (final t in custom)
                  Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: PabColors.lilac,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PabColors.lilacText,
                    ),
                    onDeleted: () => setState(() => _desired[day]?.remove(t)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(int day, WeekPeriod p) {
    final state = _state(day, p);
    final on = state == 2;
    final part = state == 1;
    return Tooltip(
      message: '${p.label} · ${p.range}',
      child: Material(
        color: on
            ? PabColors.ink
            : part
            ? PabColors.soft
            : PabColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: on
                ? PabColors.ink
                : part
                ? PabColors.accent
                : PabColors.line,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _toggle(day, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              part ? '${p.label} (parte)' : p.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : PabColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
