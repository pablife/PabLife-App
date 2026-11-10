import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/women_diary_entry.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/pabi/pabi.dart';
import '../pages/mood_check_in_page.dart';
import '../women_health_controller.dart';
import 'diary_page.dart';
import 'diary_widgets.dart';
import 'women_diary_controller.dart';

/// "Nova anotação" do diário (canvas Fem-Diario-M-Nova): humor, rotina, três
/// perguntas e compartilhar. Depois de salvar mostra o resumo.
class DiaryEntryPage extends StatefulWidget {
  final DateTime day;

  /// Abre direto no resumo (quando já existe anotação e ela só quer ver).
  final bool viewOnly;

  const DiaryEntryPage({super.key, required this.day, this.viewOnly = false});

  static Future<void> open({DateTime? day, bool viewOnly = false}) async {
    await Get.to<void>(
      () => DiaryEntryPage(
        day: WomenDiaryController.dateOnly(day ?? DateTime.now()),
        viewOnly: viewOnly,
      ),
      routeName: "/women-diary/entry",
    );
  }

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _Prompt {
  final String question;
  final String hint;
  final TextEditingController controller = TextEditingController();

  _Prompt(this.question, this.hint);
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _diary = WomenDiaryController.to;
  final _women = WomenHealthController.to;

  final Set<DiaryHabit> _habits = {};
  late final List<_Prompt> _prompts = [
    _Prompt(
      'Como foi meu dia?',
      'Ex.: acordei cedo, trabalhei de casa, fui à academia',
    ),
    _Prompt('O que me fez bem?', 'Uma coisa pequena já vale'),
    _Prompt('Quero lembrar ou levar para a consulta', 'Opcional'),
  ];
  bool _shared = false;
  bool _saving = false;
  WomenDiaryEntry? _saved;

  @override
  void initState() {
    super.initState();
    final existing = _diary.entryOn(widget.day);
    if (existing != null) _fill(existing);
    if (widget.viewOnly && existing != null) _saved = existing;
    for (final p in _prompts) {
      p.controller.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showDiaryPrivacyOnce(context),
    );
  }

  void _fill(WomenDiaryEntry e) {
    _habits
      ..clear()
      ..addAll(e.habits);
    _prompts[0].controller.text = e.dayText ?? '';
    _prompts[1].controller.text = e.feltGood ?? '';
    _prompts[2].controller.text = e.toRemember ?? '';
    _shared = e.shared;
  }

  @override
  void dispose() {
    for (final p in _prompts) {
      p.controller.dispose();
    }
    super.dispose();
  }

  bool get _isEmpty =>
      _habits.isEmpty &&
      _prompts.every((p) => p.controller.text.trim().isEmpty);

  bool get _isToday => widget.day == WomenDiaryController.today;

  String get _subtitle {
    final cycle = _women.cycleDayOrNull(widget.day);
    return [
      diaryDateLabel(widget.day),
      if (cycle != null) 'Dia $cycle do ciclo',
    ].join(' · ');
  }

  Future<void> _save() async {
    if (_isEmpty || _saving) return;
    setState(() => _saving = true);
    final saved = await _diary.save(
      day: widget.day,
      habits: DiaryHabit.values.where(_habits.contains).toList(),
      dayText: _prompts[0].controller.text,
      feltGood: _prompts[1].controller.text,
      toRemember: _prompts[2].controller.text,
      shared: _shared,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      AppSnackbar.to.show('Não foi possível salvar agora. Tente de novo.');
      return;
    }
    setState(() => _saved = saved);
  }

  Future<void> _changeMood() async {
    await MoodCheckInPage.open();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Scaffold(
      backgroundColor: PabColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(saved != null),
                Expanded(child: saved == null ? _editor() : _summary(saved)),
                if (saved == null) _saveBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool saved) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          DiaryBackButton(onTap: () => Get.back<void>()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saved
                      ? 'Meu diário'
                      : _diary.entryOn(widget.day) == null
                      ? 'Nova anotação'
                      : 'Editar anotação',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _subtitle,
                  style: const TextStyle(fontSize: 12, color: PabColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- escrever

  Widget _editor() {
    final mood = diaryMoodOn(widget.day);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Material(
          color: PabColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: PabColors.line),
          ),
          child: InkWell(
            // O "Como estou hoje" registra só o dia de hoje.
            onTap: _isToday ? _changeMood : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Pabi(mood: PabiMood.fromCheckIn(mood), women: true, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isToday ? 'Humor de hoje' : 'Humor do dia',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PabColors.muted,
                          ),
                        ),
                        Text(
                          mood ?? 'Ainda não registrado',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isToday)
                    Text(
                      mood == null ? 'Registrar' : 'Mudar',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PabColors.accentText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _Title('Minha rotina hoje'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final habit in DiaryHabit.values)
              DiaryPill(
                label: habit.label,
                selected: _habits.contains(habit),
                check: true,
                onTap: () => setState(() {
                  if (!_habits.remove(habit)) _habits.add(habit);
                }),
              ),
          ],
        ),
        for (final p in _prompts) ...[
          const SizedBox(height: 18),
          _Title(p.question),
          const SizedBox(height: 8),
          TextField(
            controller: p.controller,
            minLines: 3,
            maxLines: 8,
            maxLength: 4000,
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: PabColors.ink,
            ),
            cursorColor: PabColors.ink,
            decoration: InputDecoration(
              hintText: p.hint,
              hintStyle: const TextStyle(color: PabColors.muted),
              filled: true,
              fillColor: PabColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: PabColors.lineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: PabColors.accent, width: 2),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Material(
          color: PabColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PabColors.line),
          ),
          child: InkWell(
            onTap: () => setState(() => _shared = !_shared),
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compartilhar com minha psicóloga',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: PabColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _shared
                                ? 'Ela verá esta anotação no seu prontuário'
                                : 'Desligado: só você vê esta anotação',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PabColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shared,
                      onChanged: (v) => setState(() => _shared = v),
                      activeThumbColor: PabColors.card,
                      activeTrackColor: PabColors.pink,
                      inactiveThumbColor: PabColors.card,
                      inactiveTrackColor: const Color(0xFFD5C8DA),
                      trackOutlineColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveBar() {
    final enabled = !_isEmpty && !_saving;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: PabColors.card,
        border: Border(top: BorderSide(color: PabColors.line)),
      ),
      child: FilledButton(
        onPressed: enabled ? _save : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: PabColors.pink,
          foregroundColor: PabColors.ink,
          disabledBackgroundColor: PabColors.track,
          disabledForegroundColor: const Color(0xFF6E5E74),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _saving ? 'Salvando…' : 'Salvar no diário',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- salvo

  Widget _summary(WomenDiaryEntry e) {
    final mood = diaryMoodOn(e.day);
    final texts = e.texts;
    final reply = (e.feltGood ?? '').trim().isNotEmpty
        ? 'Guarde esse momento bom. Ele faz parte do seu ciclo também.'
        : 'Escrever ajuda a perceber padrões na sua rotina.';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Pabi(mood: PabiMood.feliz, women: true, size: 130),
              const SizedBox(height: 8),
              Text(
                widget.viewOnly
                    ? 'Sua anotação de hoje'
                    : 'Guardado no seu diário',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reply,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: PabColors.onInkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PabColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PabColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (mood != null)
                    _Chip(mood, PabColors.soft, PabColors.softText),
                  _Chip(
                    e.shared ? 'Compartilhada com a psicóloga' : 'Só você vê',
                    PabColors.background,
                    diaryBodyColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                e.habits.isEmpty
                    ? 'Rotina: nada marcado'
                    : 'Rotina: ${e.habits.map((h) => h.label).join(' · ')}',
                style: const TextStyle(fontSize: 13, color: PabColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                texts.isEmpty
                    ? 'Sem texto, só a rotina marcada.'
                    : texts.join('\n\n'),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: diaryBodyColor,
                ),
              ),
            ],
          ),
        ),
        if (widget.viewOnly) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _fill(e);
              _saved = null;
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: PabColors.accentText,
            ),
            child: const Text(
              'Editar anotação',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 10,
              child: OutlinedButton(
                onPressed: () {
                  // Volta para a lista se ela já estiver aberta embaixo.
                  var hasList = false;
                  Get.until((route) {
                    final name = route.settings.name ?? '';
                    if (name == DiaryPage.routeName) hasList = true;
                    return hasList || !name.startsWith('/women-diary');
                  });
                  if (!hasList) DiaryPage.open();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: PabColors.ink,
                  backgroundColor: PabColors.card,
                  side: const BorderSide(color: PabColors.lineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ver meu diário',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 13,
              child: FilledButton(
                onPressed: () => Get.until(
                  (route) =>
                      !(route.settings.name ?? '').startsWith('/women-diary'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: PabColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Voltar ao Dashboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: PabColors.ink,
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;

  const _Chip(this.label, this.background, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
    ),
  );
}
