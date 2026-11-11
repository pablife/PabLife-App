import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/pabi/pabi.dart';
import '../../dashboard/dashboard_controller.dart';
import '../diary/diary_entry_page.dart';
import '../diary/women_diary_controller.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

/// Para onde leva a sugestão depois do registro.
enum _Go { note, professionals }

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

// Mensagens da PABI do canvas "PABI · Expressões e mensagens" (sugestões que
// devem ser revisadas por um psicólogo da equipe).
const _moods = [
  _MoodText(
    'Feliz',
    PabiMood.feliz,
    'Que alegria! Guarde esse momento, ele é seu.',
    'Que alegria! Guarde esse momento, ele é seu.',
    'Anotar o que te fez bem',
    'Anotar',
    _Go.note,
    'O que te fez bem hoje?',
    ['Hoje eu me senti bem porque ', 'Sou grata por ', 'Quero repetir '],
  ),
  _MoodText(
    'Bem',
    PabiMood.bem,
    'Que bom! Aproveite esse dia leve.',
    'Que bom! Aproveite esse dia leve.',
    'Anotar o que deixou o dia leve',
    'Anotar',
    _Go.note,
    'O que deixou o dia leve?',
    ['Hoje eu consegui ', 'Me ajudou ', 'Quero manter '],
  ),
  _MoodText(
    'Cansada',
    PabiMood.cansada,
    'Descanse um pouquinho, você merece.',
    'Descanse um pouquinho, você merece.',
    'Anotar o que pesou hoje',
    'Anotar',
    _Go.note,
    'O que pesou hoje?',
    ['Estou cansada porque ', 'Eu precisava de ', 'Amanhã quero '],
  ),
  _MoodText(
    'Enjoada',
    PabiMood.enjoada,
    'Goles de água e refeições leves podem ajudar. Se continuar, fale com seu médico.',
    'Goles de água e refeições leves podem ajudar. Se continuar, fale com seu médico.',
    'Anotar quando o enjoo aparece',
    'Anotar',
    _Go.note,
    'Quando o enjoo aparece?',
    ['O enjoo começou ', 'Piora quando ', 'O que aliviou foi '],
  ),
  _MoodText(
    'Ansiosa',
    PabiMood.ansiosa,
    'Respire fundo, uma coisa de cada vez. Quer conversar com um psicólogo?',
    'Respire fundo, uma coisa de cada vez. Quer conversar com um psicólogo?',
    'Conversar com um psicólogo',
    'Ver',
    _Go.professionals,
    'O que está na sua cabeça agora?',
    [
      'Estou preocupada com ',
      'O que eu posso controlar é ',
      'Um passo pequeno seria ',
    ],
  ),
  _MoodText(
    'Emotiva',
    PabiMood.emotiva,
    'Sentir muito também faz parte. Estou aqui com você.',
    'Sentir muito também faz parte. Estou aqui com você.',
    'Escrever o que você está sentindo',
    'Escrever',
    _Go.note,
    'O que mexeu com você hoje?',
    ['Hoje eu senti ', 'Me emocionei com ', 'Eu preciso de '],
  ),
  _MoodText(
    'Sensível',
    PabiMood.sensivel,
    'Você sente fundo, e tudo bem. Vá com calma e cuide de você.',
    'Você sente fundo, e tudo bem. Vá com calma e cuide de você.',
    'Escrever o que você está sentindo',
    'Escrever',
    _Go.note,
    'O que você está sentindo?',
    ['Hoje eu me senti ', 'Eu preciso de ', 'Quero ser gentil comigo e '],
  ),
  _MoodText(
    'Triste',
    PabiMood.triste,
    'Sinto muito. Você não precisa passar por isso sozinha. Que tal falar com um psicólogo da Pablife?',
    'Sinto muito. Você não precisa passar por isso sozinha. Que tal falar com um psicólogo da Pablife?',
    'Conversar com um psicólogo da Pablife',
    'Ver',
    _Go.professionals,
    'Quer contar o que aconteceu?',
    ['Hoje eu senti ', 'O que me deixou assim foi ', 'Eu gostaria de '],
  ),
];

/// Conselhos para cada humor: três aparecem por vez e "Ver outros
/// conselhos" mostra os seguintes.
const _advice = <String, List<String>>{
  'Feliz': [
    'Anote três coisas que deram certo hoje. Lembrar delas ajuda nos dias difíceis.',
    'Repare no que trouxe esse bem-estar (sono, companhia, movimento) e tente repetir.',
    'Compartilhe a alegria: mande uma mensagem para alguém que faz parte desse momento.',
    'Aproveite a energia para algo que você vem adiando, sem se sobrecarregar.',
    'Celebre as pequenas conquistas. Elas contam tanto quanto as grandes.',
    'Mexa o corpo de um jeito gostoso: dançar uma música já vale.',
  ],
  'Bem': [
    'Guarde esse estado: respire fundo três vezes e repare como o corpo está.',
    'Use o dia leve para organizar o amanhã sem pressa.',
    'Uma caminhada leve ou um alongamento ajudam a manter o ritmo.',
    'Diminua as telas à noite para proteger o sono.',
    'Reserve um tempo só seu: um livro, um chá, uma música.',
    'Anote o que deixou o dia leve, para voltar a isso quando precisar.',
  ],
  'Cansada': [
    'Faça uma pausa de 5 minutos: feche os olhos, solte os ombros e respire devagar.',
    'Beba um copo de água. A falta de água aumenta o cansaço.',
    'Escolha só uma ou duas tarefas importantes hoje e deixe o resto para amanhã.',
    'Se puder, durma mais cedo e deixe o celular longe da cama.',
    'Um lanche com proteína e fruta dá energia mais estável do que doce.',
    'Peça ajuda: dividir tarefas também é cuidar de você. Se o cansaço durar semanas, converse com um médico.',
  ],
  'Triste': [
    'Permita-se sentir. Chorar e desacelerar fazem parte.',
    'Converse com alguém de confiança, nem que seja uma mensagem curta.',
    'Abra a janela ou saia um pouco: a luz do dia ajuda o humor.',
    'Faça uma coisa pequena e gentil por você: um banho quente, uma música, um chá.',
    'Evite decisões grandes hoje. Elas podem esperar.',
    'Se a tristeza durar mais de duas semanas, uma psicóloga pode te ajudar.',
  ],
  'Ansiosa': [
    'Respire assim: puxe o ar em 4 segundos, segure 4 e solte em 6. Repita 5 vezes.',
    'Faça o 5-4-3-2-1: repare em 5 coisas que vê, 4 que toca, 3 que ouve, 2 cheiros e 1 sabor.',
    'Escreva o que preocupa e separe o que está nas suas mãos do que não está.',
    'Divida o que assusta em um primeiro passo bem pequeno e comece por ele.',
    'Hoje, diminua o café e as notícias.',
    'Caminhe 10 minutos: mexer o corpo diminui a tensão.',
  ],
  'Emotiva': [
    'Deixe a emoção vir: chorar ou rir à toa também faz parte.',
    'Escreva umas linhas sobre o que mexeu com você hoje.',
    'Converse com alguém de confiança, nem que seja uma mensagem curta.',
    'Respire devagar: puxe o ar em 4 segundos e solte em 6.',
    'Repare se o sono, a fome ou os hormônios estão pesando hoje.',
    'Se as emoções estiverem difíceis de levar, um psicólogo pode ajudar.',
  ],
  'Enjoada': [
    'Beba água em goles pequenos ao longo do dia.',
    'Prefira refeições leves e em pequenas porções, várias vezes ao dia.',
    'Biscoito de água e sal ou uma fruta podem ajudar ao acordar.',
    'Evite cheiros fortes e alimentos muito gordurosos.',
    'Descanse depois de comer, sem deitar logo em seguida.',
    'Remédio, só com orientação. Se o enjoo for forte ou não passar, fale com seu médico.',
  ],
  'Sensível': [
    'Fale com você como falaria com uma amiga querida.',
    'Diminua os estímulos: menos barulho e telas, mais conforto.',
    'Diga não ao que pode esperar. Hoje você pode ir devagar.',
    'Um abraço, um banho quente ou uma coberta já fazem diferença.',
    'Dar nome ao que sente ajuda a entender: escreva umas linhas.',
    'Nos dias antes da menstruação é comum ficar mais sensível. Isso passa.',
  ],
};

_MoodText? _moodByLabel(String? label) =>
    _moods.where((m) => m.label == label).firstOrNull;

enum _Step { pick, saved }

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
  final _diary = WomenDiaryController.to;
  final _text = TextEditingController();

  _Step _step = _Step.pick;
  String? _mood;
  final Set<String> _symptoms = {};
  int? _energy;
  String? _sleep;
  bool _saving = false;

  /// Acabou de salvar (o título agradece); senão só está revendo.
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    final today = _women.todayCheckIn;
    if (_moodByLabel(today) != null) {
      _mood = today;
      // Já registrou hoje: abre mostrando o registro, não o formulário.
      _step = _Step.saved;
    }
    // O texto do dia mora no diário.
    _text.text = _diary.todayEntry?.dayText ?? '';
    _women.todayDetails().then((details) {
      if (!mounted || details == null) return;
      setState(() {
        _symptoms.addAll(
          List<String>.from(details['symptoms'] as List? ?? const []),
        );
        _energy = details['energy'] as int?;
        _sleep = details['sleep'] as String?;
      });
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  _MoodText? get _current => _moodByLabel(_mood);

  /// Ansiosa ou triste nos últimos 3 dias seguidos (hoje incluído).
  bool get _heavyStreak {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(
      3,
      (i) => today.subtract(Duration(days: i)),
    ).every((d) => const ['Ansiosa', 'Triste'].contains(_women.checkInOn(d)));
  }

  String get _title => switch (_step) {
    _Step.pick => 'Como estou hoje',
    _Step.saved => _justSaved ? 'Obrigada por registrar' : 'Registro de hoje',
  };

  Future<void> _save() async {
    final mood = _mood;
    if (mood == null || _saving) return;
    setState(() => _saving = true);
    final ok = await _women.saveTodayCheckIn(
      mood: mood,
      symptoms: _symptoms.toList(),
      energy: _energy,
      sleep: _sleep,
    );
    // "Quer contar algo?" fica no diário, como "Como foi meu dia?".
    final textOk = ok && await _diary.saveTodayText(_text.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      AppSnackbar.to.show('Não foi possível salvar agora. Tente de novo.');
      return;
    }
    if (!textOk) {
      AppSnackbar.to.show('O humor foi salvo, mas o texto não. Tente de novo.');
    }
    setState(() {
      _justSaved = true;
      _step = _Step.saved;
    });
  }

  /// A anotação do dia fica no "Meu diário".
  Future<void> _openDiary() async {
    await DiaryEntryPage.open();
    if (mounted) setState(() {});
  }

  void _follow(_Go go) {
    switch (go) {
      case _Go.note:
        _openDiary();
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

  void _back() => Get.back<void>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
              Pabi(mood: current?.face ?? PabiMood.bem, women: true, size: 170),
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
              Pabi(mood: current?.face ?? PabiMood.bem, women: true, size: 160),
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
          if (_heavyStreak) ...[
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Você registrou ansiosa ou triste nos últimos dias. '
                    'Conversar com um psicólogo da Pablife pode ajudar.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => _follow(_Go.professionals),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: PabColors.ink,
                      foregroundColor: PabColors.onInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Falar com um psicólogo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _AdviceCard(tips: _advice[current.label] ?? const []),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current.tip,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
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
            onTap: _openDiary,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_note, size: 20, color: PabColors.ink),
                  const SizedBox(width: 8),
                  Text(
                    _diary.todayEntry == null
                        ? 'Escrever no meu diário'
                        : 'Ver no meu diário',
                    style: const TextStyle(
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

  const _TextBox({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 7,
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
  static const text = 'Seus registros são privados. Só você vê.';

  const _PrivacyLine();

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

/// "Conselhos para hoje": três por vez; "Ver outros conselhos" mostra os
/// seguintes.
class _AdviceCard extends StatefulWidget {
  final List<String> tips;

  const _AdviceCard({required this.tips});

  @override
  State<_AdviceCard> createState() => _AdviceCardState();
}

class _AdviceCardState extends State<_AdviceCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final tips = widget.tips;
    if (tips.isEmpty) return const SizedBox.shrink();
    final pages = (tips.length / 3).ceil();
    final shown = tips.skip((_page % pages) * 3).take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: PabColors.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: PabColors.softText,
              ),
              SizedBox(width: 8),
              Text(
                'Conselhos para hoje',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: PabColors.softText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final tip in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: const BoxDecoration(
                      color: PabColors.menstruation,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (pages > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _page++),
                style: TextButton.styleFrom(
                  foregroundColor: PabColors.softText,
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 18),
                label: const Text(
                  'Ver outros conselhos',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
