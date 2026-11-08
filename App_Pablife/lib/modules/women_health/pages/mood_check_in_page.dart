import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../infra/models/activity_model.dart';
import '../../../infra/repositories/activity_repository.dart';
import '../../../infra/services/activity_service.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/pabi/pabi.dart';
import '../../dashboard/dashboard_controller.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

/// Para onde leva a sugestão depois do registro.
enum _Go { note, mentorias, professionals }

/// O que a Pabi diz para cada humor (canvas "Como estou hoje").
class _MoodText {
  final String label;
  final PabiMood face;
  final String bubble;
  final String reply;
  final String tip;
  final String cta;
  final _Go go;
  final String prompt;
  final List<String> starters;

  const _MoodText(
    this.label,
    this.face,
    this.bubble,
    this.reply,
    this.tip,
    this.cta,
    this.go,
    this.prompt,
    this.starters,
  );
}

const _moods = [
  _MoodText(
    'Feliz',
    PabiMood.feliz,
    'Que bom! Seu sorriso aparece aqui.',
    'Que dia bom! Guarde esse momento.',
    'Anotar o que te fez bem',
    'Anotar',
    _Go.note,
    'O que te fez bem hoje?',
    ['Hoje eu me senti bem porque ', 'Sou grata por ', 'Quero repetir '],
  ),
  _MoodText(
    'Tranquila',
    PabiMood.tranquila,
    'Que bom te ver em paz.',
    'Aproveite essa calma. Ela é sua.',
    'Uma mentoria para manter o ritmo',
    'Ver',
    _Go.mentorias,
    'O que trouxe essa calma?',
    ['Hoje eu consegui ', 'Me ajudou ', 'Quero manter '],
  ),
  _MoodText(
    'Cansada',
    PabiMood.cansada,
    'Dia pesado, né? Tudo bem.',
    'Descansar também é cuidar de você.',
    'Uma pausa guiada de 5 minutos',
    'Pausar',
    _Go.mentorias,
    'O que pesou hoje?',
    ['Estou cansada porque ', 'Eu precisava de ', 'Amanhã quero '],
  ),
  _MoodText(
    'Triste',
    PabiMood.triste,
    'Sinto muito que hoje esteja difícil.',
    'Obrigada por contar. Hoje não precisa ser perfeito.',
    'Conversar com uma psicóloga',
    'Agendar',
    _Go.professionals,
    'Quer contar o que aconteceu?',
    ['Hoje eu senti ', 'O que me deixou assim foi ', 'Eu gostaria de '],
  ),
  _MoodText(
    'Ansiosa',
    PabiMood.ansiosa,
    'Respira comigo: 4 segundos dentro, 4 fora.',
    'Um passo de cada vez. Você está indo bem.',
    'Respiração guiada de 2 minutos',
    'Respirar',
    _Go.mentorias,
    'O que está na sua cabeça agora?',
    [
      'Estou preocupada com ',
      'O que eu posso controlar é ',
      'Um passo pequeno seria ',
    ],
  ),
  _MoodText(
    'Irritada',
    PabiMood.irritada,
    'Tudo bem sentir raiva.',
    'Escrever sobre o que aconteceu pode aliviar.',
    'Desabafar numa anotação',
    'Escrever',
    _Go.note,
    'O que aconteceu?',
    ['O que aconteceu foi ', 'Eu senti ', 'Da próxima vez eu '],
  ),
  _MoodText(
    'Com cólica',
    PabiMood.colica,
    'Ai, cólica! Uma bolsa morna pode ajudar.',
    'Vá com calma hoje. Seu corpo está trabalhando.',
    'Registrar a intensidade da dor',
    'Registrar',
    _Go.note,
    'Como está a dor hoje?',
    ['A dor começou ', 'O que aliviou foi ', 'A intensidade de 0 a 10 é '],
  ),
  _MoodText(
    'Sensível',
    PabiMood.sensivel,
    'Dias sensíveis pedem gentileza.',
    'Seja gentil com você mesma hoje.',
    'Uma mentoria de autocuidado',
    'Ver',
    _Go.mentorias,
    'O que você está sentindo?',
    ['Hoje eu me senti ', 'Eu preciso de ', 'Quero ser gentil comigo e '],
  ),
];

_MoodText? _moodByLabel(String? label) =>
    _moods.where((m) => m.label == label).firstOrNull;

enum _Step { pick, saved, note, noteSaved }

const _sleepOptions = [
  ('bem', 'Bem'),
  ('mais_ou_menos', 'Mais ou menos'),
  ('mal', 'Mal'),
];

/// "Como estou hoje" (canvas "Registro de humor — Saúde da Mulher"):
/// humor com a Pabi, sintomas, energia, sono e texto; depois a resposta da
/// Pabi, uma sugestão, a semana e a anotação do dia.
class MoodCheckInPage extends StatefulWidget {
  const MoodCheckInPage({super.key});

  static Future<void> open() async {
    await Get.to<void>(() => const MoodCheckInPage());
  }

  @override
  State<MoodCheckInPage> createState() => _MoodCheckInPageState();
}

class _MoodCheckInPageState extends State<MoodCheckInPage> {
  final _women = WomenHealthController.to;
  final _text = TextEditingController();
  final _note = TextEditingController();

  _Step _step = _Step.pick;
  String? _mood;
  final Set<String> _symptoms = {};
  int? _energy;
  String? _sleep;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = _women.todayCheckIn;
    if (_moodByLabel(today) != null) _mood = today;
    _women.todayDetails().then((details) {
      if (!mounted || details == null) return;
      setState(() {
        _symptoms.addAll(
          List<String>.from(details['symptoms'] as List? ?? const []),
        );
        _energy = details['energy'] as int?;
        _sleep = details['sleep'] as String?;
        _text.text = details['note'] as String? ?? '';
      });
    });
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _note.dispose();
    super.dispose();
  }

  _MoodText? get _current => _moodByLabel(_mood);

  String get _title => switch (_step) {
    _Step.pick => 'Como estou hoje',
    _Step.saved => 'Obrigada por registrar',
    _Step.note => 'Nova anotação',
    _Step.noteSaved => 'Anotação salva',
  };

  Future<void> _save() async {
    final mood = _mood;
    if (mood == null || _saving) return;
    setState(() => _saving = true);
    final text = _text.text.trim();
    final ok = await _women.saveTodayCheckIn(
      mood: mood,
      symptoms: _symptoms.toList(),
      energy: _energy,
      sleep: _sleep,
      note: text.isEmpty ? null : text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      AppSnackbar.to.show('Não foi possível salvar agora. Tente de novo.');
      return;
    }
    setState(() => _step = _Step.saved);
  }

  /// Guarda a anotação na agenda, no dia de hoje. Só a própria pessoa vê.
  Future<void> _saveNote() async {
    final text = _note.text.trim();
    final userId = AuthService.instance.currentUser?.id;
    if (text.isEmpty || userId == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final firstLine = text.split('\n').first.trim();
    final name = firstLine.length > 60
        ? '${firstLine.substring(0, 57)}…'
        : firstLine;
    final response = await ActivityRepository().createActivity(
      ActivityModel(
        id: '',
        userId: userId,
        type: 'note',
        name: name,
        description: text == firstLine ? null : text,
        priority: 'medium',
        dueAt: now.toUtc(),
        allDay: false,
        timezone: tz.local.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success || response.data == null) {
      AppSnackbar.to.show(response.message);
      return;
    }
    ActivityService.instance
      ..addActivity(response.data!)
      ..refresh();
    setState(() => _step = _Step.noteSaved);
  }

  void _follow(_Go go) {
    switch (go) {
      case _Go.note:
        setState(() => _step = _Step.note);
      case _Go.mentorias:
        _leaveTo(2);
      case _Go.professionals:
        _leaveTo(3);
    }
  }

  void _leaveTo(int tab) {
    Get.back<void>();
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(tab);
    }
  }

  void _back() {
    switch (_step) {
      case _Step.note:
        setState(() => _step = _Step.saved);
      case _Step.pick || _Step.saved || _Step.noteSaved:
        Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != _Step.note,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = _Step.saved);
      },
      child: Scaffold(
        backgroundColor: PabColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Expanded(
                    child: switch (_step) {
                      _Step.pick => _pick(),
                      _Step.saved => _saved(),
                      _Step.note => _noteEditor(),
                      _Step.noteSaved => _noteSaved(),
                    },
                  ),
                  if (_step == _Step.pick)
                    _bottomButton(
                      label: _saving
                          ? 'Salvando…'
                          : _mood == null
                          ? 'Escolha como você se sente'
                          : 'Salvar registro',
                      onTap: _mood == null ? null : _save,
                    ),
                  if (_step == _Step.note)
                    _bottomButton(
                      label: _saving ? 'Salvando…' : 'Salvar anotação',
                      onTap: _note.text.trim().isEmpty ? null : _saveNote,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- partes

  Widget _header() {
    final date = DateFormat(
      "EEEE, d 'de' MMMM",
      'pt_BR',
    ).format(DateTime.now());
    final badge = _women.isActive ? _women.ringValue : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Tooltip(
            message: 'Voltar',
            child: Material(
              color: PabColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: PabColors.line),
              ),
              child: InkWell(
                onTap: _back,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back, size: 20, color: PabColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date[0].toUpperCase()}${date.substring(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PabColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null && badge != '—')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: PabColors.soft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: PabColors.menstruation,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: PabColors.softText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pick() {
    final current = _current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        // A Pabi muda de rosto com a escolha e fala com a pessoa.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          decoration: BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  current?.bubble ?? 'Oi! Como você está se sentindo hoje?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Pabi(
                mood: current?.face ?? PabiMood.tranquila,
                women: true,
                size: 170,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Heading('Como você se sente?'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 3 * 8) / 4;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _moods)
                  SizedBox(
                    width: width,
                    child: _MoodButton(
                      mood: m,
                      selected: _mood == m.label,
                      onTap: () => setState(() => _mood = m.label),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const _Heading('Sintomas de hoje', optional: true),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _women.symptomOptions)
              _Pill(
                label: s,
                selected: _symptoms.contains(s),
                onTap: () => setState(() {
                  if (!_symptoms.remove(s)) _symptoms.add(s);
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _Heading('Sua energia'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var n = 1; n <= 5; n++) ...[
              if (n > 1) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: 'Energia $n de 5',
                  selected: _energy == n,
                  button: true,
                  excludeSemantics: true,
                  child: _Box(
                    selected: _energy == n,
                    height: 46,
                    onTap: () => setState(() => _energy = n),
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _energy == n ? Colors.white : PabColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sem energia',
              style: TextStyle(fontSize: 12, color: PabColors.muted),
            ),
            Text(
              'Muita energia',
              style: TextStyle(fontSize: 12, color: PabColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Heading('Como você dormiu?'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (value, label) in _sleepOptions) ...[
              if (value != 'bem') const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  label: label,
                  selected: _sleep == value,
                  expand: true,
                  onTap: () => setState(() => _sleep = value),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const _Heading('Quer contar algo?', optional: true),
        const SizedBox(height: 8),
        _TextBox(controller: _text, hint: 'Escreva como foi seu dia'),
        const SizedBox(height: 14),
        const _PrivacyLine(),
      ],
    );
  }

  Widget _saved() {
    final current = _current;
    final showPain =
        _mood == 'Com cólica' ||
        _symptoms.contains('Cólica') ||
        _symptoms.contains('Fluxo intenso');
    final showSupport = _mood == 'Triste' || _mood == 'Ansiosa';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: PabColors.pink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: Color(0xFFFFC2E6)),
                    SizedBox(width: 6),
                    Text(
                      'Registro salvo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFC2E6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Pabi(
                mood: current?.face ?? PabiMood.tranquila,
                women: true,
                size: 160,
              ),
              const SizedBox(height: 8),
              Text(
                current?.reply ?? 'Obrigada por contar como você está.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: PabColors.onInk,
                ),
              ),
            ],
          ),
        ),
        if (current != null) ...[
          const SizedBox(height: 14),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sugestão para agora',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PabColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current.tip,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _follow(current.go),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: PabColors.pink,
                    foregroundColor: PabColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    current.cta,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showPain) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Se a dor for forte, diferente do habitual ou não passar, '
              'procure sua ginecologista.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: PabColors.softText,
              ),
            ),
          ),
        ],
        if (showSupport) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PabColors.lilac,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você não precisa passar por isso sozinha',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B4D),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Se os dias difíceis continuarem, conversar com uma '
                  'psicóloga ajuda. Se precisar de apoio agora, ligue 188 '
                  '(CVV), a qualquer hora.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: PabColors.lilacText,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Material(
          color: PabColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PabColors.pink),
          ),
          child: InkWell(
            onTap: () => setState(() => _step = _Step.note),
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 20, color: PabColors.ink),
                  SizedBox(width: 8),
                  Text(
                    'Escrever uma anotação sobre hoje',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Week(women: _women),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => setState(() => _step = _Step.pick),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: PabColors.accentText,
          ),
          child: const Text(
            'Editar o registro de hoje',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _noteEditor() {
    final current = _current ?? _moods[1];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Row(
          children: [
            Pabi(mood: current.face, women: true, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                current.prompt,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Para começar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: PabColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final starter in current.starters)
              _Pill(
                label: '${starter.trim()}…',
                selected: false,
                onTap: () {
                  final before = _note.text;
                  _note.text = before.isEmpty ? starter : '$before\n$starter';
                  _note.selection = TextSelection.collapsed(
                    offset: _note.text.length,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        _TextBox(
          controller: _note,
          hint: 'Escreva aqui',
          lines: 8,
          autofocus: true,
        ),
        const SizedBox(height: 12),
        const _PrivacyLine(
          text: 'A anotação fica na sua agenda, no dia de hoje. Só você vê.',
        ),
      ],
    );
  }

  Widget _noteSaved() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Center(
          child: Pabi(
            mood: _current?.face ?? PabiMood.feliz,
            women: true,
            size: 150,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Anotação guardada na sua agenda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PabColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Você encontra em Agenda, no dia de hoje.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: PabColors.muted),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => _leaveTo(1),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: PabColors.pink,
            foregroundColor: PabColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Abrir agenda',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Get.back<void>(),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: PabColors.ink,
          ),
          child: const Text(
            'Voltar ao Dashboard',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _bottomButton({required String label, required VoidCallback? onTap}) {
    final enabled = onTap != null && !_saving;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: PabColors.card,
        border: Border(top: BorderSide(color: PabColors.line)),
      ),
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: PabColors.pink,
          foregroundColor: PabColors.ink,
          disabledBackgroundColor: PabColors.track,
          disabledForegroundColor: PabColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- peças

class _Heading extends StatelessWidget {
  final String text;
  final bool optional;

  const _Heading(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (optional)
            const TextSpan(
              text: ' (opcional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PabColors.muted,
              ),
            ),
        ],
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: PabColors.ink,
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final _MoodText mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? PabColors.pink : PabColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 88,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Pabi(mood: mood.face, women: true, size: 48),
                const SizedBox(height: 2),
                Text(
                  mood.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? PabColors.ink : PabColors.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? PabColors.ink : PabColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : PabColors.ink,
                      ),
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

class _Box extends StatelessWidget {
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  const _Box({
    required this.selected,
    required this.height,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PabColors.ink : PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? PabColors.ink : PabColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int lines;
  final bool autofocus;

  const _TextBox({
    required this.controller,
    required this.hint,
    this.lines = 3,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: lines,
      maxLines: lines + 4,
      maxLength: 2000,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, color: PabColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: PabColors.muted),
        filled: true,
        fillColor: PabColors.card,
        counterText: '',
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: border(PabColors.lineStrong),
        focusedBorder: border(PabColors.ink),
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  final String text;

  const _PrivacyLine({this.text = 'Seus registros são privados. Só você vê.'});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: PabColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: PabColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Os últimos sete dias com o rosto da Pabi de cada registro e a faixa da
/// menstruação.
class _Week extends StatelessWidget {
  final WomenHealthController women;

  const _Week({required this.women});

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    const letters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final period = days
        .where(
          (d) => women.cyclePhaseOn(d)?.kind == WomenCycleKind.menstruation,
        )
        .toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sua semana',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              if (period.isNotEmpty)
                Text(
                  'Menstruação: ${period.length} '
                  '${period.length == 1 ? 'dia' : 'dias'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PabColors.accentText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: switch (women.checkInOn(day)) {
                            final String label => Pabi(
                              mood: PabiMood.fromCheckIn(label),
                              women: true,
                              size: 32,
                            ),
                            null => Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: PabColors.line),
                              ),
                            ),
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: period.contains(day)
                              ? PabColors.menstruation
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day == today ? 'Hoje' : letters[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: day == today
                              ? PabColors.accentText
                              : PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
