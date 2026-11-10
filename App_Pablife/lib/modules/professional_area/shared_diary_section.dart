import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../infra/models/women_diary_entry.dart';
import '../../infra/repositories/women_diary_repository.dart';
import '../../shared/themes/pab_colors.dart';

/// Anotações do "Meu diário" que a paciente escolheu compartilhar. Somente
/// leitura. O banco só devolve as compartilhadas, e só para quem tem vínculo
/// com ela: nada privado chega aqui. Sem nenhuma, a seção não aparece.
class SharedDiarySection extends StatefulWidget {
  final String patientUserId;

  const SharedDiarySection({super.key, required this.patientUserId});

  @override
  State<SharedDiarySection> createState() => _SharedDiarySectionState();
}

class _SharedDiarySectionState extends State<SharedDiarySection> {
  List<WomenDiaryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SharedDiarySection old) {
    super.didUpdateWidget(old);
    if (old.patientUserId != widget.patientUserId) _load();
  }

  Future<void> _load() async {
    try {
      final rows = await WomenDiaryRepository().listSharedByPatient(
        widget.patientUserId,
      );
      // Segurança extra: mesmo que o banco mude, só mostra as compartilhadas.
      _entries = rows.where((e) => e.shared).toList();
    } catch (_) {
      _entries = [];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Diário compartilhado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              Text(
                'a paciente escolheu mostrar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PabColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in _entries) ...[
            _SharedEntry(entry: e),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SharedEntry extends StatelessWidget {
  final WomenDiaryEntry entry;

  const _SharedEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(entry.day);
    final title = '${date[0].toUpperCase()}${date.substring(1)}';
    final questions = [
      ('Como foi o dia', entry.dayText),
      ('O que fez bem', entry.feltGood),
      ('Para lembrar / levar à consulta', entry.toRemember),
    ].where((q) => (q.$2 ?? '').trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PabColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          if (entry.cycleDay != null)
            Text(
              'Dia ${entry.cycleDay} do ciclo',
              style: const TextStyle(fontSize: 12, color: PabColors.muted),
            ),
          if (entry.habits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Rotina: ${entry.habits.map((h) => h.label).join(' · ')}',
              style: const TextStyle(fontSize: 12, color: PabColors.muted),
            ),
          ],
          for (final (label, text) in questions) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: PabColors.accentText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text!.trim(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: PabColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
