/// Data de nascimento digitada como dd/mm/aaaa e a regra dos 18 anos.
abstract final class BirthDate {
  static const minimumAge = 18;

  static const tooYoungMessage =
      'O Pablife é para maiores de $minimumAge anos.';

  /// Lê "dd/mm/aaaa". Devolve null se estiver incompleta, se o dia não existir
  /// (ex.: 31/02) ou se a data for anterior a 1900 ou futura.
  static DateTime? parse(String text, {DateTime? now}) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    if (year < 1900 || date.isAfter(now ?? DateTime.now())) return null;
    return date;
  }

  static int age(DateTime birth, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final hadBirthday =
        today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    return today.year - birth.year - (hadBirthday ? 0 : 1);
  }

  static bool isAdult(DateTime birth, {DateTime? now}) =>
      age(birth, now: now) >= minimumAge;

  /// O que mostrar embaixo do campo; null se a data vale.
  static String? errorFor(String text, {DateTime? now}) {
    final date = parse(text, now: now);
    if (date == null) return 'Digite uma data válida, como 25/08/1990.';
    return isAdult(date, now: now) ? null : tooYoungMessage;
  }

  /// "dd/mm/aaaa" para mostrar na tela.
  static String format(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${_four(date.year)}';

  /// "aaaa-mm-dd" para o banco, sem fuso: o dia não muda.
  static String toDatabase(DateTime date) =>
      '${_four(date.year)}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _four(int n) => n.toString().padLeft(4, '0');
}
