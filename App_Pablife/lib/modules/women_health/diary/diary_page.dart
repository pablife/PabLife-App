import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/women_diary_entry.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/pabi/pabi.dart';
import 'diary_entry_page.dart';
import 'diary_widgets.dart';
import 'women_diary_controller.dart';

enum _Filter { all, week, shared }

/// "Meu diário" (canvas Fem-Diario-M): a semana, filtros e as anotações.
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  static const routeName = '/women-diary/list';

  static Future<void> open() async {
    await Get.to<void>(() => const DiaryPage(), routeName: routeName);
  }

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    final diary = WomenDiaryController.to;
    if (!diary.loaded) diary.load();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showDiaryPrivacyOnce(context),
    );
  }

  List<WomenDiaryEntry> _visible(WomenDiaryController c) {
    final start = WomenDiaryController.weekStart(WomenDiaryController.today);
    final end = start.add(const Duration(days: 7));
    return c.entries.where((e) {
      return switch (_filter) {
        _Filter.all => true,
        _Filter.week => !e.day.isBefore(start) && e.day.isBefore(end),
        _Filter.shared => e.shared,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PabColors.background,
      body: GetBuilder<WomenDiaryController>(
        builder: (c) {
          final visible = _visible(c);
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WeekHeader(controller: c),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: RefreshIndicator(
                          color: PabColors.accentText,
                          onRefresh: c.load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final (f, label) in const [
                                    (_Filter.all, 'Todas'),
                                    (_Filter.week, 'Esta semana'),
                                    (_Filter.shared, 'Compartilhadas'),
                                  ])
                                    DiaryPill(
                                      label: label,
                                      selected: _filter == f,
                                      onTap: () => setState(() => _filter = f),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (c.loading && c.entries.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: PabColors.accentText,
                                    ),
                                  ),
                                )
                              else if (visible.isEmpty)
                                _Empty(filter: _filter)
                              else
                                for (final e in visible) ...[
                                  _EntryCard(entry: e),
                                  const SizedBox(height: 12),
                                ],
                              const SizedBox(height: 4),
                              const Text(
                                'Com o tempo, a Pabi mostra como sua rotina e '
                                'seu humor mudam ao longo do ciclo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: PabColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 528),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: PabColors.ink.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: () => DiaryEntryPage.open(),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            c.todayEntry == null
                                ? 'Escrever sobre hoje'
                                : 'Editar a anotação de hoje',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: PabColors.pink,
                            foregroundColor: PabColors.ink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final WomenDiaryController controller;

  const _WeekHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final today = WomenDiaryController.today;
    final start = WomenDiaryController.weekStart(today);
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    const letters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final written = days.where(controller.hasEntryOn).length;

    return Container(
      color: PabColors.ink,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DiaryBackButton(
                        onTap: () => Get.back<void>(),
                        onDark: true,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meu diário',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PabColors.onInk,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Privado · você escolhe o que compartilhar',
                              style: TextStyle(
                                fontSize: 13,
                                color: PabColors.onInkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    label: 'Esta semana: anotações em $written de 7 dias',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        for (var i = 0; i < 7; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: _WeekDay(
                              letter: letters[i],
                              day: days[i],
                              has: controller.hasEntryOn(days[i]),
                              isToday: days[i] == today,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String letter;
  final DateTime day;
  final bool has;
  final bool isToday;

  const _WeekDay({
    required this.letter,
    required this.day,
    required this.has,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          letter,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PabColors.navIdle,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday ? PabColors.onInkSoft : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: has
                  ? PabColors.pink
                  : PabColors.onInk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: has ? PabColors.ink : PabColors.navIdle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final WomenDiaryEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mood = diaryMoodOn(entry.day);
    final meta = diaryMeta(entry);
    final texts = entry.texts;
    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PabColors.line),
      ),
      child: InkWell(
        onTap: () => DiaryEntryPage.open(day: entry.day),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: PabColors.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Pabi(
                      mood: PabiMood.fromCheckIn(mood),
                      women: true,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diaryDateLabel(entry.day),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            style: const TextStyle(
                              fontSize: 12,
                              color: PabColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DiaryShareBadge(shared: entry.shared),
                ],
              ),
              if (texts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  texts.join('\n\n'),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: diaryBodyColor,
                  ),
                ),
              ],
              if (entry.habits.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final h in entry.habits) DiaryTag(h.label)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final _Filter filter;

  const _Empty({required this.filter});

  @override
  Widget build(BuildContext context) {
    final text = switch (filter) {
      _Filter.all => 'Seu diário ainda está em branco. Que tal começar hoje?',
      _Filter.week => 'Nenhuma anotação nesta semana ainda.',
      _Filter.shared => 'Nenhuma anotação compartilhada com sua psicóloga.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Pabi(mood: PabiMood.tranquila, women: true, size: 90),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: PabColors.muted),
          ),
        ],
      ),
    );
  }
}
