import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/modules/women_health/pregnancy/pregnancy_models.dart';

void main() {
  group('semana de referência (ilustração)', () {
    test('usa a mais próxima entre 8 e 40', () {
      expect(nearestReferenceWeek(4), 8);
      expect(nearestReferenceWeek(9), 8);
      expect(nearestReferenceWeek(11), 12);
      expect(nearestReferenceWeek(20), 20);
      expect(nearestReferenceWeek(21), 20);
      expect(nearestReferenceWeek(39), 40);
      expect(nearestReferenceWeek(42), 40);
    });
  });

  test('pressão alta a partir de 140/90', () {
    expect(isHighPressure('110/70'), isFalse);
    expect(isHighPressure('139/89'), isFalse);
    expect(isHighPressure('140/80'), isTrue);
    expect(isHighPressure('120/90'), isTrue);
    expect(isHighPressure('12 por 8'), isFalse);
    expect(isHighPressure(null), isFalse);
  });

  test('textos "Título. Frase" viram itens', () {
    final tips = parseTips(
      'Pele protegida. Começa a ser coberta.\nComeça a ouvir. Sons de fora.',
    );
    expect(tips, hasLength(2));
    expect(tips.first.title, 'Pele protegida.');
    expect(tips.first.text, 'Começa a ser coberta.');
    expect(parseTips(null), isEmpty);
    expect(parseTips('Sem ponto'), [(title: '', text: 'Sem ponto')]);
  });

  test('medidas no formato brasileiro', () {
    expect(formatCm(25), '25 cm');
    expect(formatCm(1.6), '1,6 cm');
    expect(formatG(300), '300 g');
    expect(formatG(1700), '1,7 kg');
    expect(formatG(1000), '1 kg');
    expect(formatKg(64.2), '64,2 kg');
  });

  test('semana e dias da gestação', () {
    final p = Pregnancy.fromMap({
      'id': 'x',
      'dum': '2026-06-22',
      'dpp': '2027-03-29',
      'week': 20,
      'day': 2,
      'days_left': 138,
      'trimester': 2,
      'ref_week': 20,
    });
    expect(p.weekAndDays, '20 semanas e 2 dias');
    expect(p.weekOn(DateTime(2026, 11, 3)), 19);
    expect(trimesterLabel(p.week), '2º trimestre');
  });

  test('tipo de registro desconhecido vira anotação', () {
    expect(PregnancyRecordType.of('ultrassom'), PregnancyRecordType.ultrassom);
    expect(PregnancyRecordType.of('outro'), PregnancyRecordType.anotacao);
  });
}
