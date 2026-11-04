import 'package:flutter/material.dart';

/// Cores do modo Saúde da mulher.
abstract final class WomenColors {
  static const plum = Color(0xFF4A3560);
  static const ink = Color(0xFF2E1F3F);
  static const text = Color(0xFF3B2A4D);
  static const muted = Color(0xFF6B5A7B);
  static const light = Color(0xFFF4EEE9);
  static const lightMuted = Color(0xFFE4D9EC);
  static const lilac = Color(0xFFAD94EE);
  static const violet = Color(0xFF8F72E0);
  static const rose = Color(0xFFEEC3D8);
  static const mauve = Color(0xFFD6A6DB);
  static const soft = Color(0xFFE3D8F8);
  static const blush = Color(0xFFF1E7EE);
  static const paper = Color(0xFFFBF8F6);
  static const background = Color(0xFFF7F1EF);
  static const line = Color(0xFFE6D9E8);
  static const ringTrack = Color(0xFF6A5384);
}

enum WomenTrail {
  cycle(
    'Ciclo menstrual',
    'Fases do ciclo, sintomas, humor e previsão da próxima menstruação.',
    WomenColors.mauve,
  ),
  conceive(
    'Quero gestar',
    'Janela fértil estimada, tentativa e apoio emocional.',
    WomenColors.lilac,
  ),
  pregnancy(
    'Gestação',
    'Semana a semana, data provável do parto e pré-natal.',
    WomenColors.rose,
  ),
  menopause(
    'Menopausa',
    'Sintomas da transição, sono, humor e tempo sem menstruar.',
    WomenColors.violet,
  );

  final String title;
  final String description;
  final Color color;

  const WomenTrail(this.title, this.description, this.color);
}

/// Pergunta do questionário: com opções ou com data.
class WomenQuestion {
  final String id;
  final String text;
  final List<String> options;
  final bool isDate;
  final String? help;

  /// Texto do botão para quem não lembra a data (só onde dá para seguir sem).
  final String? unknownLabel;

  const WomenQuestion({
    required this.id,
    required this.text,
    this.options = const [],
    this.isDate = false,
    this.help,
    this.unknownLabel,
  });
}

const _lastPeriod = WomenQuestion(
  id: 'last_period',
  text: 'Quando começou sua última menstruação?',
  isDate: true,
);

const _feeling = WomenQuestion(
  id: 'feeling',
  text: 'Como você está se sentindo emocionalmente?',
  options: ['Bem', 'Ansiosa', 'Sobrecarregada', 'Prefiro não dizer'],
);

const cycleLengthOptions = {
  'Menos de 25 dias': 24,
  'De 25 a 32 dias': 28,
  'Mais de 32 dias': 34,
  'Não sei': 28,
};

final Map<WomenTrail, List<WomenQuestion>> womenQuiz = {
  WomenTrail.cycle: [
    _lastPeriod,
    WomenQuestion(
      id: 'cycle_length',
      text: 'Quanto dura seu ciclo, em média?',
      options: cycleLengthOptions.keys.toList(),
    ),
    const WomenQuestion(
      id: 'regular',
      text: 'Seu ciclo costuma ser regular?',
      options: ['Sim', 'Às vezes varia', 'Não', 'Não sei'],
    ),
    const WomenQuestion(
      id: 'focus',
      text: 'O que você mais quer acompanhar?',
      options: [
        'Entender meu corpo',
        'Aliviar sintomas (TPM, cólica)',
        'Humor e emoções',
        'Alimentação em cada fase',
      ],
    ),
  ],
  WomenTrail.conceive: [
    const WomenQuestion(
      id: 'trying',
      text: 'Há quanto tempo você está tentando?',
      options: [
        'Ainda vou começar',
        'Menos de 6 meses',
        'De 6 a 12 meses',
        'Mais de 12 meses',
      ],
    ),
    _lastPeriod,
    const WomenQuestion(
      id: 'doctor',
      text: 'Já conversou com um médico sobre a tentativa?',
      options: ['Sim, faço acompanhamento', 'Ainda não', 'Pretendo marcar'],
    ),
    _feeling,
  ],
  WomenTrail.pregnancy: [
    const WomenQuestion(
      id: 'last_period',
      text: 'Qual foi o primeiro dia da sua última menstruação?',
      isDate: true,
      help:
          'Usamos essa data para estimar a semana da gestação. O ultrassom '
          'costuma ser mais preciso.',
    ),
    const WomenQuestion(
      id: 'first_pregnancy',
      text: 'É sua primeira gestação?',
      options: ['Sim', 'Não'],
    ),
    const WomenQuestion(
      id: 'prenatal',
      text: 'Você já faz pré-natal?',
      options: ['Sim', 'Ainda não', 'Vou começar'],
    ),
    _feeling,
  ],
  WomenTrail.menopause: [
    const WomenQuestion(
      id: 'last_period',
      text: 'Quando foi sua última menstruação?',
      isDate: true,
      unknownLabel: 'Não lembro',
    ),
    const WomenQuestion(
      id: 'main_symptom',
      text: 'O que mais incomoda hoje?',
      options: ['Calorões', 'Sono', 'Humor', 'Outros sintomas'],
    ),
    const WomenQuestion(
      id: 'hormone',
      text: 'Você faz reposição hormonal?',
      options: ['Sim', 'Não', 'Estou avaliando com meu médico'],
    ),
    _feeling,
  ],
};

/// Opção do check-in "Como você está hoje?".
class WomenMood {
  final String label;
  final String emoji;

  const WomenMood(this.label, this.emoji);
}

const womenMoods = [
  WomenMood('Bem', '🙂'),
  WomenMood('Feliz', '😄'),
  WomenMood('Calma', '😌'),
  WomenMood('Energética', '🤩'),
  WomenMood('Ansiosa', '😰'),
  WomenMood('Triste', '😢'),
  WomenMood('Raiva', '😠'),
  WomenMood('Irritada', '😤'),
  WomenMood('Cansada', '😴'),
  WomenMood('Desanimada', '😞'),
  WomenMood('Confusa', '😕'),
];

const womenMenopauseSymptoms = [
  WomenMood('Calorão', '🥵'),
  WomenMood('Sono ruim', '🥱'),
];

WomenMood? womenMoodByLabel(String? label) {
  for (final mood in [...womenMoods, ...womenMenopauseSymptoms]) {
    if (mood.label == label) return mood;
  }
  return null;
}

class WomenTile {
  final String label;
  final String value;
  final String note;
  final Color color;

  const WomenTile(this.label, this.value, this.note, this.color);
}

class WomenNotice {
  final String title;
  final String when;

  const WomenNotice(this.title, this.when);
}

/// Faixa colorida do dia na agenda (fase, semana ou sintoma).
class WomenBand {
  final String label;
  final Color color;
  final Color textColor;

  const WomenBand(this.label, this.color, this.textColor);
}

/// Textos de apoio de cada trilha.
class WomenCareCopy {
  final String title;
  final String text;
  final String medical;
  final List<WomenNotice> notices;

  const WomenCareCopy({
    required this.title,
    required this.text,
    required this.medical,
    required this.notices,
  });
}

const womenCare = {
  WomenTrail.cycle: WomenCareCopy(
    title: 'Cuidar de você em cada fase',
    text:
        'Se a TPM, a cólica ou as mudanças de humor atrapalham seu dia a dia, '
        'uma psicóloga ou uma nutricionista pode ajudar.',
    medical:
        'Cólica muito forte ou sangramento intenso? Procure seu ginecologista.',
    notices: [
      WomenNotice('Sua menstruação deve chegar em 2 dias.', '2 dias antes'),
      WomenNotice('Check-in: como estão seu humor e sua energia?', 'Todo dia'),
      WomenNotice('Dica da nutricionista para esta fase.', 'Uma vez por fase'),
    ],
  ),
  WomenTrail.conceive: WomenCareCopy(
    title: 'Cada ciclo conta, e você não está sozinha',
    text:
        'A tentativa pode trazer ansiedade e frustração. Conversar com uma '
        'psicóloga ajuda a atravessar essa fase com mais leveza.',
    medical:
        'Tentando há 12 meses (ou 6, se tiver 35 anos ou mais)? Procure um '
        'ginecologista para avaliação.',
    notices: [
      WomenNotice('Sua janela fértil começa amanhã.', '1 dia antes'),
      WomenNotice(
        'Se a menstruação atrasar, já dá para fazer o teste.',
        'No fim do ciclo',
      ),
      WomenNotice(
        'Converse com seu médico sobre ácido fólico.',
        'Uma vez por mês',
      ),
    ],
  ),
  WomenTrail.pregnancy: WomenCareCopy(
    title: 'Cuidar da mente também é pré-natal',
    text:
        'Ansiedade e sobrecarga são comuns na gestação. Uma psicóloga e uma '
        'nutricionista podem acompanhar você em cada trimestre.',
    medical:
        'Sangramento, dor forte ou perda de líquido? Procure atendimento '
        'médico imediatamente.',
    notices: [
      WomenNotice('Você entrou em uma nova semana.', 'Toda semana'),
      WomenNotice('Sua consulta de pré-natal é amanhã.', '1 dia antes'),
      WomenNotice('Dica da nutricionista para esta fase.', 'Semanal'),
    ],
  ),
  WomenTrail.menopause: WomenCareCopy(
    title: 'Uma fase que merece cuidado',
    text:
        'Mudanças de humor e sono afetam o dia a dia. Uma psicóloga e uma '
        'nutricionista podem ajudar você nessa transição.',
    medical:
        'Sangramento após 12 meses sem menstruar? Procure seu ginecologista.',
    notices: [
      WomenNotice('Como foram calorões, sono e humor?', 'Toda semana'),
      WomenNotice('Dica da nutricionista: cálcio e vitamina D.', 'Quinzenal'),
      WomenNotice(
        'Leve seu resumo de sintomas para a consulta.',
        'Antes da consulta',
      ),
    ],
  ),
};

const womenDisclaimer =
    'As previsões são estimativas. O Pablife não substitui consulta médica e '
    'não é método contraceptivo.';
