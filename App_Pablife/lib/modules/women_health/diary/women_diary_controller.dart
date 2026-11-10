import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../infra/models/women_diary_entry.dart';
import '../../../infra/repositories/women_diary_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../women_health_controller.dart';

/// Estado do "Meu diário" (Saúde da Mulher): as anotações da usuária, uma
/// por dia. Fica em memória enquanto o app está aberto.
class WomenDiaryController extends GetxController {
  static WomenDiaryController get to => Get.isRegistered<WomenDiaryController>()
      ? Get.find<WomenDiaryController>()
      : Get.put(WomenDiaryController(), permanent: true);

  final WomenDiaryRepository _repository = WomenDiaryRepository();

  /// Da mais recente para a mais antiga.
  List<WomenDiaryEntry> entries = [];
  bool loading = false;
  bool loaded = false;

  String? get _userId => AuthService.instance.currentUser?.id;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime get today => dateOnly(DateTime.now());

  /// Segunda-feira da semana de [day].
  static DateTime weekStart(DateTime day) {
    final d = dateOnly(day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null || loading) return;
    loading = true;
    update();
    try {
      entries = await _repository.listAll(userId);
      loaded = true;
    } catch (e) {
      debugPrint('Erro ao carregar o diário: $e');
    } finally {
      loading = false;
      update();
    }
  }

  WomenDiaryEntry? entryOn(DateTime day) {
    final d = dateOnly(day);
    return entries.firstWhereOrNull((e) => dateOnly(e.day) == d);
  }

  WomenDiaryEntry? get todayEntry => entryOn(today);

  bool hasEntryOn(DateTime day) => entryOn(day) != null;

  /// Anotações desta semana (segunda a domingo).
  int get weekCount {
    final start = weekStart(today);
    final end = start.add(const Duration(days: 7));
    return entries
        .where((e) => !e.day.isBefore(start) && e.day.isBefore(end))
        .length;
  }

  /// Pergunta do card no Dashboard: muda a cada dia.
  static const prompts = [
    'O que te fez bem hoje?',
    'Como foi sua manhã?',
    'O que você quer lembrar de hoje?',
  ];

  String get dailyPrompt {
    final t = today;
    final dayOfYear = t.difference(DateTime(t.year)).inDays;
    return prompts[dayOfYear % prompts.length];
  }

  /// Grava a anotação do dia. Devolve a versão salva, ou null se falhou.
  Future<WomenDiaryEntry?> save({
    required DateTime day,
    required List<DiaryHabit> habits,
    required String dayText,
    required String feltGood,
    required String toRemember,
    required bool shared,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    final women = Get.isRegistered<WomenHealthController>()
        ? WomenHealthController.to
        : null;
    try {
      final saved = await _repository.upsert(
        WomenDiaryEntry(
          userId: userId,
          day: dateOnly(day),
          habits: habits,
          dayText: dayText,
          feltGood: feltGood,
          toRemember: toRemember,
          cycleDay: women?.cycleDayOrNull(day),
          shared: shared,
        ),
      );
      _replace(saved);
      return saved;
    } catch (e) {
      debugPrint('Erro ao salvar o diário: $e');
      return null;
    }
  }

  /// Texto "Como foi meu dia?" vindo do "Como estou hoje".
  Future<bool> saveTodayText(String? text) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.saveDayText(userId, today, text);
      final fresh = await _repository.getByDay(userId, today);
      entries.removeWhere((e) => dateOnly(e.day) == today);
      if (fresh != null) _replace(fresh);
      update();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar o texto no diário: $e');
      return false;
    }
  }

  void _replace(WomenDiaryEntry entry) {
    entries.removeWhere((e) => dateOnly(e.day) == dateOnly(entry.day));
    entries
      ..add(entry)
      ..sort((a, b) => b.day.compareTo(a.day));
    update();
  }

  // ------------------------------------------------------------ privacidade

  String get _privacyKey => 'women_diary_privacy_seen_${_userId ?? 'anon'}';

  /// Já viu o aviso "Seu diário é privado"?
  Future<bool> privacySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_privacyKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markPrivacySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyKey, true);
    } catch (_) {}
  }
}
