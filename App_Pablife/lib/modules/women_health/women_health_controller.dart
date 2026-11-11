import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/models/user_role.dart';
import '../../infra/repositories/women_health_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../infra/repositories/user_preferences_repository.dart';
import '../../shared/themes/app_palette.dart';
import '../../shared/utils/app_snackbar.dart';
import '../auth/entry_visual.dart';
import 'pregnancy/pregnancy_controller.dart';
import 'women_health_data.dart';

/// Modo Saúde da mulher. Os dados ficam na conta da usuária, em tabelas que
/// só ela consegue ler.
class WomenHealthController extends GetxController {
  static WomenHealthController get to => Get.find<WomenHealthController>();

  final WomenHealthRepository _repository = WomenHealthRepository();

  WomenTrail? trail;
  DateTime? lastPeriod;
  int cycleLength = 28;
  Map<String, String> answers = {};

  /// Check-in de cada dia ('2026-11-04' => 'Calma').
  Map<String, String> checkIns = {};

  /// Registros de menstruação, tentativas e testes.
  List<WomenLog> logs = [];

  /// Caixa da trilha em "Mostrar": liga a faixa na agenda.
  bool showBand = true;

  bool get isActive => trail != null;

  final _loaded = Completer<void>();

  /// Completa quando a trilha da conta terminou de carregar.
  Future<void> get ready => _loaded.future;

  String get _legacyStorageKey =>
      'women_health_${AuthService.instance.currentUser?.id ?? 'anon'}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime get _today => _dateOnly(DateTime.now());

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String shortDate(DateTime d) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${d.day}/${months[d.month - 1]}';
  }

  @override
  void onInit() {
    super.onInit();
    _load().whenComplete(() {
      if (!_loaded.isCompleted) _loaded.complete();
    });
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;
    if (user?.id == null) return;
    // O modo é do lado usuário. O profissional só escolhe o visual, que
    // fica guardado no cadastro.
    if (user!.role != UserRole.user) {
      try {
        AppPalette.apply(
          await UserPreferencesRepository().loadRoseTheme() ?? false,
        );
      } catch (e) {
        debugPrint('Erro ao carregar o visual: $e');
      }
      return;
    }

    try {
      final userId = user.id!;
      await _moveLocalDataToAccount(userId);
      final profile = await _repository.getProfile(userId);
      checkIns = await _repository.getCheckIns(userId);
      await _loadLogs(userId);
      trail = WomenTrail.values.firstWhereOrNull(
        (t) => t.name == profile?['trail'],
      );
      final period = profile?['last_period'] as String?;
      lastPeriod = period == null ? null : DateTime.parse(period);
      cycleLength = profile?['cycle_length'] as int? ?? 28;
      answers = Map<String, String>.from(profile?['answers'] as Map? ?? {});
      // Conta nova que escolheu a Saúde da Mulher fica no visual rosé
      // enquanto responde o questionário.
      if (!EntryVisual.waitingWomenFlow) AppPalette.apply(isActive);
      update();
    } catch (e) {
      debugPrint('Erro ao carregar Saúde da mulher: $e');
    }
  }

  /// A versão de teste guardava tudo no aparelho: leva para a conta uma vez.
  Future<void> _moveLocalDataToAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyStorageKey);
    if (raw == null) return;

    if (await _repository.getProfile(userId) == null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      await _repository.saveProfile(
        userId: userId,
        trail: data['trail'] as String?,
        lastPeriod: data['last_period'] as String?,
        cycleLength: data['cycle_length'] as int? ?? 28,
        answers: Map<String, String>.from(data['answers'] as Map? ?? {}),
        consentAt: DateTime.now(),
      );
      final saved = Map<String, String>.from(data['check_ins'] as Map? ?? {});
      for (final entry in saved.entries) {
        await _repository.saveCheckIn(userId, entry.key, entry.value);
      }
    }
    await prefs.remove(_legacyStorageKey);
  }

  String? get _userId => AuthService.instance.currentUser?.id;

  Future<bool> _save({DateTime? consentAt}) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.saveProfile(
        userId: userId,
        trail: trail?.name,
        lastPeriod: lastPeriod == null ? null : _dayKey(lastPeriod!),
        cycleLength: cycleLength,
        answers: answers,
        consentAt: consentAt,
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar Saúde da mulher: $e');
      AppSnackbar.to.show('Não foi possível salvar. Tente novamente.');
      return false;
    }
  }

  // ---------------------------------------------------------------- ações

  /// Só liga o modo depois de salvar. Devolve false se não conseguiu.
  Future<bool> start({
    required WomenTrail newTrail,
    required Map<String, String> newAnswers,
    required DateTime? newLastPeriod,
  }) async {
    final previousTrail = trail;
    final previousAnswers = answers;
    final previousPeriod = lastPeriod;
    final previousLength = cycleLength;
    trail = newTrail;
    answers = newAnswers;
    lastPeriod = newLastPeriod;
    cycleLength = cycleLengthOptions[newAnswers['cycle_length']] ?? 28;

    if (!await _save(consentAt: DateTime.now())) {
      trail = previousTrail;
      answers = previousAnswers;
      lastPeriod = previousPeriod;
      cycleLength = previousLength;
      return false;
    }

    showBand = true;
    AppPalette.apply(true);
    UserPreferencesRepository().saveTheme(rose: true);
    update();
    // Gestação: cria (ou atualiza a DUM) do acompanhamento; ao trocar de
    // trilha, encerra o anterior (para os avisos semanais).
    if (newTrail == WomenTrail.pregnancy) {
      PregnancyController.to.load();
    } else if (previousTrail == WomenTrail.pregnancy) {
      PregnancyController.to.endPregnancy();
    }
    return true;
  }

  /// "Sair do modo": só acontece quando a usuária confirma. Os registros
  /// (ciclo, respostas e humor) continuam guardados na conta.
  Future<void> exit() async {
    if (trail == WomenTrail.pregnancy) {
      await PregnancyController.to.endPregnancy();
    }
    trail = null;
    AppPalette.apply(false);
    UserPreferencesRepository().saveTheme(rose: false);
    update();
    await _save();
  }

  void setShowBand(bool value) {
    showBand = value;
    update();
  }

  /// "Minha menstruação veio hoje": recomeça a contagem do ciclo.
  Future<void> registerPeriodToday() => registerPeriodStart(_today);

  // ------------------------------------------------------------ registros

  Future<void> _loadLogs(String userId) async {
    try {
      final rows = await _repository.getLogs(userId);
      logs = [
        for (final r in rows)
          WomenLog(
            DateTime.parse(r['day'] as String),
            r['kind'] as String,
            r['value'] as String?,
          ),
      ];
    } catch (e) {
      debugPrint('Registros da Saúde da Mulher: $e');
    }
  }

  WomenLog? logOn(DateTime day, String kind) {
    final d = _dateOnly(day);
    return logs.firstWhereOrNull((l) => l.kind == kind && l.day == d);
  }

  List<WomenLog> logsOf(String kind) =>
      logs.where((l) => l.kind == kind).toList()
        ..sort((a, b) => b.day.compareTo(a.day));

  /// Começos de menstruação registrados (do mais antigo ao mais novo).
  List<DateTime> get periodStarts =>
      logsOf(WomenLog.periodStart).map((l) => l.day).toList().reversed.toList();

  /// Histórico de ciclos, do mais novo para o mais antigo.
  List<WomenCycleRecord> get cycleHistory {
    final starts = periodStarts;
    final ends = logsOf(WomenLog.periodEnd).map((l) => l.day).toList();
    return [
      for (var i = starts.length - 1; i >= 0; i--)
        WomenCycleRecord(
          starts[i],
          ends.firstWhereOrNull(
            (e) =>
                !e.isBefore(starts[i]) &&
                e.difference(starts[i]).inDays < 15 &&
                (i == starts.length - 1 || e.isBefore(starts[i + 1])),
          ),
          i == starts.length - 1
              ? null
              : starts[i + 1].difference(starts[i]).inDays,
        ),
    ];
  }

  /// Média dos últimos ciclos registrados (21 a 45 dias), ou null.
  int? get averageCycle {
    final lengths = cycleHistory
        .map((c) => c.length)
        .whereType<int>()
        .where((n) => n >= 21 && n <= 45)
        .take(6)
        .toList();
    if (lengths.isEmpty) return null;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Dias de atraso da menstruação (0 se não está atrasada).
  int get daysLate {
    if (lastPeriod == null) return 0;
    final expected = lastPeriod!.add(Duration(days: cycleLength));
    final late = _today.difference(expected).inDays;
    return late > 0 ? late : 0;
  }

  /// Marcou "não veio" depois da última menstruação?
  bool get markedNoPeriod {
    final last = lastPeriod;
    return logsOf(
      WomenLog.noPeriod,
    ).any((l) => last == null || l.day.isAfter(last));
  }

  Future<bool> _saveLog(DateTime day, String kind, {String? value}) async {
    final userId = _userId;
    if (userId == null) return false;
    final d = _dateOnly(day);
    final previous = logOn(d, kind);
    logs
      ..removeWhere((l) => l.kind == kind && l.day == d)
      ..add(WomenLog(d, kind, value));
    update();
    try {
      await _repository.saveLog(userId, _dayKey(d), kind, value: value);
      return true;
    } catch (e) {
      logs.removeWhere((l) => l.kind == kind && l.day == d);
      if (previous != null) logs.add(previous);
      update();
      AppSnackbar.to.show('Não foi possível salvar. Tente novamente.');
      return false;
    }
  }

  Future<bool> removeLog(DateTime day, String kind) async {
    final userId = _userId;
    if (userId == null) return false;
    final d = _dateOnly(day);
    final previous = logOn(d, kind);
    if (previous == null) return true;
    logs.removeWhere((l) => l.kind == kind && l.day == d);
    update();
    try {
      await _repository.deleteLog(userId, _dayKey(d), kind);
      if (kind == WomenLog.periodStart) await _syncCycleFromLogs();
      return true;
    } catch (e) {
      logs.add(previous);
      update();
      AppSnackbar.to.show('Não foi possível apagar. Tente novamente.');
      return false;
    }
  }

  /// A última menstruação e o tamanho do ciclo passam a vir dos registros.
  Future<void> _syncCycleFromLogs() async {
    final starts = periodStarts;
    if (starts.isNotEmpty) lastPeriod = starts.last;
    final avg = averageCycle;
    if (avg != null) cycleLength = avg;
    update();
    await _save();
  }

  /// A menstruação começou neste dia.
  Future<void> registerPeriodStart(DateTime day) async {
    if (await _saveLog(day, WomenLog.periodStart)) await _syncCycleFromLogs();
  }

  Future<void> registerPeriodEnd(DateTime day) =>
      _saveLog(day, WomenLog.periodEnd);

  /// "Não veio este mês".
  Future<void> registerNoPeriod() => _saveLog(_today, WomenLog.noPeriod);

  Future<void> toggleAttempt(DateTime day) async {
    if (logOn(day, WomenLog.attempt) != null) {
      await removeLog(day, WomenLog.attempt);
    } else {
      await _saveLog(day, WomenLog.attempt);
    }
  }

  /// Teste do dia (ovulação ou gravidez). Tocar de novo na mesma opção
  /// apaga.
  Future<void> setTest(DateTime day, String kind, String value) async {
    if (logOn(day, kind)?.value == value) {
      await removeLog(day, kind);
    } else {
      await _saveLog(day, kind, value: value);
    }
  }

  Future<void> toggleCheckIn(String value) async {
    final key = _dayKey(_today);
    final previous = checkIns[key];
    final remove = previous == value;
    if (remove) {
      checkIns.remove(key);
    } else {
      checkIns[key] = value;
    }
    update();

    final userId = _userId;
    if (userId == null) return;
    try {
      if (remove) {
        await _repository.deleteCheckIn(userId, key);
      } else {
        await _repository.saveCheckIn(userId, key, value);
      }
    } catch (e) {
      debugPrint('Erro ao salvar humor: $e');
      if (previous == null) {
        checkIns.remove(key);
      } else {
        checkIns[key] = previous;
      }
      update();
      AppSnackbar.to.show('Não foi possível salvar o humor.');
    }
  }

  String? get todayCheckIn => checkIns[_dayKey(_today)];

  /// Humor registrado num dia (para a semana na tela "Como estou hoje").
  String? checkInOn(DateTime day) => checkIns[_dayKey(_dateOnly(day))];

  /// Sintomas que fazem sentido para a trilha.
  List<String> get symptomOptions => switch (trail) {
    WomenTrail.pregnancy => const [
      'Enjoo',
      'Azia',
      'Inchaço',
      'Dor nas costas',
      'Sono',
      'Movimentos do bebê',
    ],
    WomenTrail.menopause => const [
      'Calorão',
      'Suor noturno',
      'Insônia',
      'Dor nas articulações',
      'Ressecamento',
      'Irritabilidade',
    ],
    _ => const [
      'Cólica',
      'Inchaço',
      'Dor de cabeça',
      'Seios sensíveis',
      'Fluxo leve',
      'Fluxo médio',
      'Fluxo intenso',
    ],
  };

  /// Detalhes já guardados hoje (para abrir a tela preenchida).
  Future<Map<String, dynamic>?> todayDetails() async {
    final userId = _userId;
    if (userId == null) return null;
    return _repository.getCheckInDetails(userId, _dayKey(_today));
  }

  /// Salva o registro de hoje (o texto do dia vai para o diário, à parte).
  /// Retorna false se nem o humor salvou.
  Future<bool> saveTodayCheckIn({
    required String mood,
    required List<String> symptoms,
    required int? energy,
    required String? sleep,
  }) async {
    final key = _dayKey(_today);
    final previous = checkIns[key];
    checkIns[key] = mood;
    update();
    final userId = _userId;
    if (userId == null) return true;
    try {
      await _repository.saveCheckIn(userId, key, mood);
    } catch (e) {
      debugPrint('Erro ao salvar humor: $e');
      if (previous == null) {
        checkIns.remove(key);
      } else {
        checkIns[key] = previous;
      }
      update();
      return false;
    }
    await _repository.saveCheckInDetails(
      userId,
      key,
      symptoms: symptoms,
      energy: energy,
      sleep: sleep,
    );
    return true;
  }

  /// Humor registrado no dia, para mostrar na agenda.
  WomenMood? moodOn(DateTime day) {
    if (!isActive || !showBand) return null;
    return womenMoodByLabel(checkIns[_dayKey(_dateOnly(day))]);
  }

  // ---------------------------------------------------------------- ciclo

  /// Dia do ciclo (1 = primeiro dia da menstruação).
  int cycleDay(DateTime day) =>
      (_dateOnly(day).difference(lastPeriod!).inDays % cycleLength) + 1;

  /// Dia do ciclo para o diário, ou null quando ela não acompanha o ciclo
  /// (gestação, menopausa, sem data da última menstruação).
  int? cycleDayOrNull(DateTime day) {
    if (lastPeriod == null) return null;
    if (trail != WomenTrail.cycle && trail != WomenTrail.conceive) return null;
    if (_dateOnly(day).isBefore(lastPeriod!)) return null;
    return cycleDay(day);
  }

  /// A ovulação costuma vir cerca de 14 dias antes da próxima menstruação.
  int get _ovulationDay => cycleLength - 14;

  String _phase(int day) {
    final ovulation = _ovulationDay;
    if (day <= 5) return 'Menstruação';
    if (day == ovulation) return 'Ovulação';
    if (day >= ovulation - 5 && day <= ovulation + 1) return 'Fértil';
    return day < ovulation ? 'Folicular' : 'Lútea';
  }

  /// Fase do dia para quem acompanha o ciclo. As próximas são previsões.
  WomenCyclePhase? cyclePhaseOn(DateTime day) {
    final date = _dateOnly(day);
    if (lastPeriod == null || date.isBefore(lastPeriod!)) return null;
    final future = date.isAfter(_today);
    return switch (_phase(cycleDay(date))) {
      'Menstruação' => WomenCyclePhase(
        WomenCycleKind.menstruation,
        future ? 'Previsão de menstruação' : 'Menstruação registrada',
      ),
      'Ovulação' => const WomenCyclePhase(
        WomenCycleKind.fertile,
        'Previsão de ovulação',
      ),
      'Fértil' => const WomenCyclePhase(
        WomenCycleKind.fertile,
        'Previsão de período fértil',
      ),
      'Folicular' => const WomenCyclePhase(
        WomenCycleKind.other,
        'Fase folicular (estimativa)',
      ),
      _ => const WomenCyclePhase(
        WomenCycleKind.other,
        'Fase lútea (estimativa)',
      ),
    };
  }

  DateTime get nextPeriod {
    final today = _today;
    final elapsed = today.difference(lastPeriod!).inDays;
    final cycles = elapsed < 0 ? 0 : elapsed ~/ cycleLength + 1;
    return DateTime(
      lastPeriod!.year,
      lastPeriod!.month,
      lastPeriod!.day + cycles * cycleLength,
    );
  }

  DateTime get _nextOvulation {
    final next = nextPeriod;
    return DateTime(next.year, next.month, next.day - 14);
  }

  /// Faixa do dia na agenda, ou null se não houver nada a mostrar.
  WomenBand? bandOn(DateTime day) {
    if (!isActive || !showBand) return null;

    if (trail == WomenTrail.menopause) return null;

    if (lastPeriod == null || _dateOnly(day).isBefore(lastPeriod!)) return null;

    if (trail == WomenTrail.pregnancy) {
      final days = _dateOnly(day).difference(lastPeriod!).inDays;
      if (days > 294) return null;
      return WomenBand('Sem. ${days ~/ 7}', WomenColors.soft, WomenColors.ink);
    }

    final phase = _phase(cycleDay(day));
    return switch (phase) {
      'Menstruação' => WomenBand(phase, WomenColors.rose, WomenColors.ink),
      'Fértil' => WomenBand(phase, WomenColors.mauve, WomenColors.ink),
      'Ovulação' => WomenBand(phase, WomenColors.violet, Colors.white),
      'Folicular' when trail == WomenTrail.cycle => WomenBand(
        phase,
        WomenColors.blush,
        WomenColors.plum,
      ),
      'Lútea' when trail == WomenTrail.cycle => WomenBand(
        phase,
        WomenColors.plum,
        WomenColors.light,
      ),
      _ => null,
    };
  }

  // -------------------------------------------------------------- resumo

  /// Check-in mais frequente dos últimos 30 dias, entre [options].
  String? _mostFrequent(List<String> options) {
    final start = _today.subtract(const Duration(days: 30));
    final counts = <String, int>{};
    checkIns.forEach((key, value) {
      if (options.contains(value) && !DateTime.parse(key).isBefore(start)) {
        counts[value] = (counts[value] ?? 0) + 1;
      }
    });
    if (counts.isEmpty) return null;
    return (counts.entries.toList()..sort((a, b) => b.value - a.value))
        .first
        .key;
  }

  WomenTile get _moodTile {
    final mood = womenMoodByLabel(
      _mostFrequent(womenMoods.map((m) => m.label).toList()),
    );
    return WomenTile(
      'Humor mais frequente',
      mood == null ? 'Sem registros' : '${mood.emoji} ${mood.label}',
      mood == null ? 'faça o check-in abaixo' : 'nos últimos 30 dias',
      WomenColors.soft,
    );
  }

  String get ringValue => switch (trail!) {
    WomenTrail.pregnancy => 'Sem. $_pregnancyWeek',
    WomenTrail.menopause => lastPeriod == null ? '—' : '$_monthsSincePeriod',
    _ => 'Dia ${cycleDay(_today)}',
  };

  String get ringUnit => switch (trail!) {
    WomenTrail.pregnancy => 'de 40',
    WomenTrail.menopause =>
      _monthsSincePeriod == 1 ? 'mês sem menstruar' : 'meses sem menstruar',
    _ => 'de $cycleLength',
  };

  double get ringFraction => switch (trail!) {
    WomenTrail.pregnancy => (_pregnancyWeek / 40).clamp(0.0, 1.0),
    WomenTrail.menopause => (_monthsSincePeriod / 12).clamp(0.0, 1.0),
    _ => cycleDay(_today) / cycleLength,
  };

  int get _pregnancyWeek => _today.difference(lastPeriod!).inDays ~/ 7;

  int get _monthsSincePeriod {
    if (lastPeriod == null) return 0;
    final today = _today;
    var months =
        (today.year - lastPeriod!.year) * 12 + today.month - lastPeriod!.month;
    if (today.day < lastPeriod!.day) months--;
    return months < 0 ? 0 : months;
  }

  DateTime get _dueDate => lastPeriod!.add(const Duration(days: 280));

  String get heroTitle {
    switch (trail!) {
      case WomenTrail.pregnancy:
        final week = _pregnancyWeek;
        return week <= 13
            ? '1º trimestre'
            : week <= 27
            ? '2º trimestre'
            : '3º trimestre';
      case WomenTrail.menopause:
        return _monthsSincePeriod >= 12
            ? 'Pós-menopausa'
            : 'Transição (perimenopausa)';
      case WomenTrail.cycle:
      case WomenTrail.conceive:
        return switch (_phase(cycleDay(_today))) {
          'Menstruação' => 'Fase menstrual',
          'Fértil' => 'Janela fértil estimada',
          'Ovulação' => 'Ovulação estimada',
          'Folicular' => 'Fase folicular',
          _ => 'Fase lútea',
        };
    }
  }

  String get heroSubtitle {
    switch (trail!) {
      case WomenTrail.pregnancy:
        return 'Ajuste a semana após o ultrassom, que é mais preciso.';
      case WomenTrail.menopause:
        return 'A menopausa é confirmada após 12 meses seguidos sem menstruar.';
      case WomenTrail.cycle:
      case WomenTrail.conceive:
        return switch (_phase(cycleDay(_today))) {
          'Menstruação' => 'Descanse quando precisar e cuide do seu conforto.',
          'Fértil' => 'Os dias com maior chance de gravidez, pela estimativa.',
          'Ovulação' => 'A energia costuma estar mais alta nesta fase.',
          'Folicular' => 'A energia costuma voltar aos poucos nesta fase.',
          _ => 'Cansaço e mudanças de humor são comuns perto da menstruação.',
        };
    }
  }

  List<WomenTile> get tiles {
    switch (trail!) {
      case WomenTrail.cycle:
        final next = nextPeriod;
        final ovulation = _nextOvulation;
        return [
          WomenTile(
            'Próxima menstruação',
            shortDate(next),
            'em ${next.difference(_today).inDays} dias · estimativa',
            WomenColors.rose,
          ),
          WomenTile(
            'Janela fértil',
            '${shortDate(ovulation.subtract(const Duration(days: 5)))} a '
                '${shortDate(ovulation.add(const Duration(days: 1)))}',
            'estimativa',
            WomenColors.mauve,
          ),
          _moodTile,
          WomenTile(
            'Duração do ciclo',
            '$cycleLength dias',
            answers['cycle_length'] == 'Não sei' ? 'valor médio' : 'informada',
            WomenColors.blush,
          ),
        ];
      case WomenTrail.conceive:
        final ovulation = _nextOvulation;
        return [
          WomenTile(
            'Ovulação provável',
            shortDate(ovulation),
            'estimativa',
            WomenColors.mauve,
          ),
          WomenTile(
            'Teste de gravidez',
            'a partir de ${shortDate(nextPeriod)}',
            'se a menstruação atrasar',
            WomenColors.rose,
          ),
          WomenTile(
            'Tempo tentando',
            answers['trying'] ?? '—',
            'informado por você',
            WomenColors.soft,
          ),
          _moodTile,
        ];
      case WomenTrail.pregnancy:
        final due = _dueDate;
        final weeksLeft = due.difference(_today).inDays ~/ 7;
        return [
          WomenTile(
            'Data provável do parto',
            '${shortDate(due)}/${due.year}',
            'estimativa',
            WomenColors.rose,
          ),
          WomenTile(
            'Faltam',
            '${weeksLeft < 0 ? 0 : weeksLeft} semanas',
            'estimativa',
            WomenColors.mauve,
          ),
          WomenTile(
            'Pré-natal',
            answers['prenatal'] ?? '—',
            'informado por você',
            WomenColors.soft,
          ),
          _moodTile,
        ];
      case WomenTrail.menopause:
        final start = _today.subtract(const Duration(days: 7));
        final hotFlashes = checkIns.entries
            .where(
              (e) =>
                  e.value == 'Calorão' &&
                  !DateTime.parse(e.key).isBefore(start),
            )
            .length;
        final left = 12 - _monthsSincePeriod;
        return [
          WomenTile(
            'Calorões na semana',
            '$hotFlashes',
            'pelos seus check-ins',
            WomenColors.rose,
          ),
          WomenTile(
            'O que mais incomoda',
            answers['main_symptom'] ?? '—',
            'informado por você',
            WomenColors.mauve,
          ),
          _moodTile,
          WomenTile(
            'Para 12 meses',
            lastPeriod == null
                ? '—'
                : left > 0
                ? 'faltam $left'
                : 'completo',
            'sem menstruar',
            WomenColors.blush,
          ),
        ];
    }
  }

  List<WomenMood> get checkInOptions => trail == WomenTrail.menopause
      ? [...womenMenopauseSymptoms, ...womenMoods]
      : womenMoods;
}
