import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/models/women_diary_entry.dart';
import 'package:pablife/modules/women_health/diary/women_diary_controller.dart';

void main() {
  test('lê a linha do banco e ignora hábito desconhecido', () {
    final e = WomenDiaryEntry.fromJson({
      'id': 'x',
      'user_id': 'u1',
      'day': '2026-11-06',
      'habits': ['agua', 'tempo_pra_mim', 'outro'],
      'day_text': 'Caminhei',
      'felt_good': null,
      'to_remember': '  ',
      'cycle_day': 5,
      'shared_with_professional': true,
      'shared_at': '2026-11-06T12:00:00Z',
    });
    expect(e.habits, [DiaryHabit.agua, DiaryHabit.tempoPraMim]);
    expect(e.texts, ['Caminhei']);
    expect(e.cycleDay, 5);
    expect(e.shared, isTrue);
    expect(e.day, DateTime(2026, 11, 6));
  });

  test('grava valores do banco e limpa textos vazios', () {
    final row = WomenDiaryEntry(
      userId: 'u1',
      day: DateTime(2026, 1, 3),
      habits: const [DiaryHabit.sono, DiaryHabit.encontro],
      dayText: '  ',
      feltGood: ' Sol ',
    ).toRow();
    expect(row['day'], '2026-01-03');
    expect(row['habits'], ['sono', 'encontro']);
    expect(row['day_text'], isNull);
    expect(row['felt_good'], 'Sol');
    expect(row['shared_with_professional'], isFalse);
    expect(row.containsKey('shared_at'), isFalse);
  });

  test('anotação sem hábito nem texto é vazia', () {
    expect(
      WomenDiaryEntry(userId: 'u', day: DateTime(2026), dayText: ' ').isEmpty,
      isTrue,
    );
    expect(
      WomenDiaryEntry(
        userId: 'u',
        day: DateTime(2026),
        habits: const [DiaryHabit.agua],
      ).isEmpty,
      isFalse,
    );
  });

  test('os valores dos hábitos são os aceitos pelo banco', () {
    expect(DiaryHabit.values.map((h) => h.value), [
      'agua',
      'exercicio',
      'alimentacao',
      'sono',
      'trabalho',
      'estudo',
      'tempo_pra_mim',
      'encontro',
    ]);
  });

  test('a semana começa na segunda', () {
    // 2026-11-08 é domingo; 2026-11-02 é segunda.
    expect(
      WomenDiaryController.weekStart(DateTime(2026, 11, 8, 15)),
      DateTime(2026, 11, 2),
    );
    expect(
      WomenDiaryController.weekStart(DateTime(2026, 11, 2)),
      DateTime(2026, 11, 2),
    );
  });
}
