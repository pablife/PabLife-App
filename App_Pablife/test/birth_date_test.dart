import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/models/gender.dart';
import 'package:pablife/shared/utils/birth_date.dart';

void main() {
  final today = DateTime(2026, 11, 25, 15, 30);

  test('lê a data digitada e guarda sem mudar o dia', () {
    final date = BirthDate.parse('05/08/1990', now: today)!;
    expect(BirthDate.toDatabase(date), '1990-08-05');
    expect(BirthDate.format(date), '05/08/1990');
  });

  test('recusa data incompleta, impossível, futura ou antiga demais', () {
    for (final text in [
      '',
      '05/08',
      '31/02/1990',
      '29/02/2001',
      '00/01/1990',
      '10/13/1990',
      '26/11/2026',
      '31/12/1899',
    ]) {
      expect(BirthDate.parse(text, now: today), isNull, reason: text);
    }
    expect(BirthDate.parse('29/02/2000', now: today), isNotNull);
  });

  test('18 anos: vale no dia do aniversário, não na véspera', () {
    expect(BirthDate.errorFor('25/11/2008', now: today), isNull);
    expect(
      BirthDate.errorFor('26/11/2008', now: today),
      BirthDate.tooYoungMessage,
    );
  });

  test('quem nasceu em 29/02 faz 18 em 1º de março', () {
    final birth = DateTime(2008, 2, 29);
    expect(BirthDate.isAdult(birth, now: DateTime(2026, 2, 28)), isFalse);
    expect(BirthDate.isAdult(birth, now: DateTime(2026, 3, 1)), isTrue);
  });

  test('gênero vai e volta do banco; desconhecido vira vazio', () {
    for (final g in Gender.values) {
      expect(Gender.fromValue(g.value), g);
    }
    expect(Gender.fromValue('xyz'), isNull);
    expect(Gender.fromValue(null), isNull);
  });
}
