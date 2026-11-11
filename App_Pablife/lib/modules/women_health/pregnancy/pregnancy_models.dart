import 'package:flutter/material.dart';

/// Gestação ativa, com os números calculados no banco.
class Pregnancy {
  final String id;
  final DateTime dum;
  final DateTime dpp;
  final int week;
  final int day;
  final int daysLeft;
  final int trimester;

  /// Semana da ilustração mais próxima (8, 12, ..., 40).
  final int refWeek;

  const Pregnancy({
    required this.id,
    required this.dum,
    required this.dpp,
    required this.week,
    required this.day,
    required this.daysLeft,
    required this.trimester,
    required this.refWeek,
  });

  factory Pregnancy.fromMap(Map<String, dynamic> m) => Pregnancy(
    id: m['id'] as String,
    dum: DateTime.parse(m['dum'] as String),
    dpp: DateTime.parse(m['dpp'] as String),
    week: m['week'] as int,
    day: m['day'] as int,
    daysLeft: m['days_left'] as int,
    trimester: m['trimester'] as int,
    refWeek: m['ref_week'] as int,
  );

  /// Semana mostrada nas telas (4 a 40).
  int get shownWeek => week.clamp(4, 40);

  String get weekAndDays {
    final w = week == 1 ? '1 semana' : '$week semanas';
    if (day == 0) return w;
    return '$w e ${day == 1 ? '1 dia' : '$day dias'}';
  }

  /// Semana da gestação numa data (para a linha do tempo).
  int weekOn(DateTime date) =>
      DateUtils.dateOnly(date).difference(dum).inDays ~/ 7;
}

String trimesterLabel(int week) => week <= 13
    ? '1º trimestre'
    : week <= 27
    ? '2º trimestre'
    : '3º trimestre';

/// Um item dos textos do conteúdo: "Título. Frase".
typedef WeekTip = ({String title, String text});

List<WeekTip> parseTips(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return [
    for (final line in raw.split('\n'))
      if (line.trim().isNotEmpty) _tip(line.trim()),
  ];
}

WeekTip _tip(String line) {
  final i = line.indexOf('. ');
  if (i < 0) return (title: '', text: line);
  return (title: line.substring(0, i + 1), text: line.substring(i + 2));
}

/// Conteúdo de uma semana. Textos só chegam quando revisados por uma
/// profissional ([reviewed]).
class PregnancyWeek {
  final int week;
  final double? lengthCm;
  final double? weightG;
  final String? comparison;
  final List<WeekTip> baby;
  final List<WeekTip> mother;
  final List<WeekTip> consult;
  final List<WeekTip> alerts;
  final String? imageUrl;
  final bool reviewed;

  const PregnancyWeek({
    required this.week,
    this.lengthCm,
    this.weightG,
    this.comparison,
    this.baby = const [],
    this.mother = const [],
    this.consult = const [],
    this.alerts = const [],
    this.imageUrl,
    this.reviewed = false,
  });

  factory PregnancyWeek.fromMap(Map<String, dynamic> m) => PregnancyWeek(
    week: m['week'] as int,
    lengthCm: (m['tamanho_cm'] as num?)?.toDouble(),
    weightG: (m['peso_g'] as num?)?.toDouble(),
    comparison: m['comparacao'] as String?,
    baby: parseTips(m['texto_bebe'] as String?),
    mother: parseTips(m['texto_mae'] as String?),
    consult: parseTips(m['texto_consulta'] as String?),
    alerts: parseTips(m['sinais_de_alerta'] as String?),
    imageUrl: m['image_url'] as String?,
    reviewed: m['reviewed'] as bool? ?? false,
  );

  String get lengthLabel => lengthCm == null ? '—' : '≈ ${formatCm(lengthCm!)}';
  String get weightLabel =>
      weightG == null ? '< 1 g' : '≈ ${formatG(weightG!)}';
}

String _num(double v, {int decimals = 1}) {
  final s = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(decimals);
  return s.replaceAll('.', ',');
}

String formatCm(double cm) => '${_num(cm)} cm';

String formatG(double g) =>
    g >= 1000 ? '${_num(g / 1000)} kg' : '${g.round()} g';

String formatKg(double kg) => '${_num(kg)} kg';

/// Semanas com ilustração.
const referenceWeeks = [8, 12, 16, 20, 24, 28, 32, 36, 40];

/// Semana de referência mais próxima de [week] (a mesma regra do banco).
int nearestReferenceWeek(int week) =>
    ((week / 4).round() * 4).clamp(8, 40).toInt();

enum PregnancyRecordType {
  consulta('Consulta de pré-natal', Icons.medical_services_outlined),
  ultrassom('Ultrassom', Icons.monitor_heart_outlined),
  exame('Exame', Icons.science_outlined),
  movimentos('Movimentos do bebê', Icons.favorite_border_rounded),
  sintoma('Sintoma', Icons.healing_outlined),
  anotacao('Anotação', Icons.edit_note_rounded);

  final String label;
  final IconData icon;

  const PregnancyRecordType(this.label, this.icon);

  static PregnancyRecordType of(String? name) => PregnancyRecordType.values
      .firstWhere((t) => t.name == name, orElse: () => anotacao);
}

const pregnancyFeelings = ['Bem', 'Cansada', 'Enjoada', 'Ansiosa', 'Emotiva'];

class PregnancyRecord {
  final String id;
  final DateTime date;
  final PregnancyRecordType type;
  final double? motherWeight;
  final String? pressure;
  final int? heartRate;
  final int? babyWeight;
  final double? babyLength;
  final String? feeling;
  final String? notes;
  final String? photoPath;
  final bool shared;

  const PregnancyRecord({
    required this.id,
    required this.date,
    required this.type,
    this.motherWeight,
    this.pressure,
    this.heartRate,
    this.babyWeight,
    this.babyLength,
    this.feeling,
    this.notes,
    this.photoPath,
    this.shared = false,
  });

  factory PregnancyRecord.fromMap(Map<String, dynamic> m) => PregnancyRecord(
    id: m['id'] as String,
    date: DateTime.parse(m['record_date'] as String),
    type: PregnancyRecordType.of(m['type'] as String?),
    motherWeight: (m['peso_mae'] as num?)?.toDouble(),
    pressure: m['pressao'] as String?,
    heartRate: m['bcf'] as int?,
    babyWeight: m['peso_estimado_bebe'] as int?,
    babyLength: (m['comprimento_estimado'] as num?)?.toDouble(),
    feeling: m['como_estou'] as String?,
    notes: m['notes'] as String?,
    photoPath: m['photo_url'] as String?,
    shared: m['shared_with_professional'] as bool? ?? false,
  );
}

/// Sinais que pedem atendimento: ao marcar um deles, o app mostra
/// "Procure atendimento agora" (sem diagnóstico).
const pregnancyAlertSigns = [
  'Sangramento',
  'Perda de líquido',
  'Bebê sem mexer',
  'Dor forte',
  'Pressão alta',
];

const pregnancyCommonSymptoms = [
  'Enjoo',
  'Azia',
  'Inchaço leve',
  'Dor nas costas',
  'Cãibra',
  'Cansaço',
];

/// Pressão a partir de 14 por 9 (140/90) é considerada alta.
bool isHighPressure(String? value) {
  final m = RegExp(r'^(\d{2,3})/(\d{2,3})$').firstMatch(value?.trim() ?? '');
  if (m == null) return false;
  return int.parse(m.group(1)!) >= 140 || int.parse(m.group(2)!) >= 90;
}

/// Aviso fixo das telas da gestação.
const pregnancyDisclaimer =
    'Valores aproximados, cada gestação é única. Não substitui o pré-natal.';

/// Sinais de alerta mostrados enquanto o conteúdo da semana não foi revisado.
const pregnancyAlertFallback =
    'Em caso de sangramento, dor forte, perda de líquido, febre, dor de '
    'cabeça intensa com visão turva ou se o bebê parar de mexer, procure um '
    'serviço de saúde.';
