/// Hábitos aceitos no "Meu diário" (mesmos valores do banco).
enum DiaryHabit {
  agua('agua', 'Bebi água'),
  exercicio('exercicio', 'Me exercitei'),
  alimentacao('alimentacao', 'Comi bem'),
  sono('sono', 'Dormi bem'),
  trabalho('trabalho', 'Trabalhei'),
  estudo('estudo', 'Estudei'),
  tempoPraMim('tempo_pra_mim', 'Tempo pra mim'),
  encontro('encontro', 'Encontrei alguém');

  final String value;
  final String label;
  const DiaryHabit(this.value, this.label);

  static DiaryHabit? fromValue(String value) =>
      values.where((h) => h.value == value).firstOrNull;
}

/// Uma anotação do "Meu diário" (uma por dia).
class WomenDiaryEntry {
  final String? id;
  final String userId;
  final DateTime day;
  final List<DiaryHabit> habits;
  final String? dayText;
  final String? feltGood;
  final String? toRemember;

  /// Dia do ciclo quando foi escrita (null fora do acompanhamento do ciclo).
  final int? cycleDay;
  final bool shared;
  final DateTime? sharedAt;

  const WomenDiaryEntry({
    this.id,
    required this.userId,
    required this.day,
    this.habits = const [],
    this.dayText,
    this.feltGood,
    this.toRemember,
    this.cycleDay,
    this.shared = false,
    this.sharedAt,
  });

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory WomenDiaryEntry.fromJson(Map<String, dynamic> json) {
    final habits = <DiaryHabit>[];
    for (final value in List<String>.from(
      json['habits'] as List? ?? const [],
    )) {
      final habit = DiaryHabit.fromValue(value);
      if (habit != null) habits.add(habit);
    }
    final sharedAt = json['shared_at'] as String?;
    return WomenDiaryEntry(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      day: DateTime.parse(json['day'] as String),
      habits: habits,
      dayText: json['day_text'] as String?,
      feltGood: json['felt_good'] as String?,
      toRemember: json['to_remember'] as String?,
      cycleDay: (json['cycle_day'] as num?)?.toInt(),
      shared: json['shared_with_professional'] as bool? ?? false,
      sharedAt: sharedAt == null ? null : DateTime.parse(sharedAt).toLocal(),
    );
  }

  /// Linha para gravar (o banco preenche id, datas e shared_at).
  Map<String, dynamic> toRow() => {
    'user_id': userId,
    'day': dayKey(day),
    'habits': habits.map((h) => h.value).toList(),
    'day_text': _clean(dayText),
    'felt_good': _clean(feltGood),
    'to_remember': _clean(toRemember),
    'cycle_day': cycleDay,
    'shared_with_professional': shared,
  };

  static String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// Os três textos que existem, na ordem das perguntas.
  List<String> get texts =>
      [dayText, feltGood, toRemember].map(_clean).whereType<String>().toList();

  bool get isEmpty => habits.isEmpty && texts.isEmpty;

  WomenDiaryEntry copyWith({
    List<DiaryHabit>? habits,
    String? dayText,
    String? feltGood,
    String? toRemember,
    bool? shared,
  }) => WomenDiaryEntry(
    id: id,
    userId: userId,
    day: day,
    habits: habits ?? this.habits,
    dayText: dayText ?? this.dayText,
    feltGood: feltGood ?? this.feltGood,
    toRemember: toRemember ?? this.toRemember,
    cycleDay: cycleDay,
    shared: shared ?? this.shared,
    sharedAt: sharedAt,
  );
}
