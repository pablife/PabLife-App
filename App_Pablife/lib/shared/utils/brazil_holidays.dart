/// Feriados nacionais do Brasil de um ano, por dia. As datas móveis saem da
/// Páscoa, então a lista vale para qualquer ano. Carnaval e Corpus Christi
/// são pontos facultativos, não feriados por lei.
Map<DateTime, String> brazilHolidays(int year) {
  return _cache.putIfAbsent(year, () {
    final easter = _easterSunday(year);
    DateTime fromEaster(int days) =>
        DateTime(easter.year, easter.month, easter.day + days);

    return {
      DateTime(year, 1, 1): 'Confraternização Universal',
      fromEaster(-48): 'Carnaval (facultativo)',
      fromEaster(-47): 'Carnaval (facultativo)',
      fromEaster(-2): 'Sexta-feira Santa',
      DateTime(year, 4, 21): 'Tiradentes',
      DateTime(year, 5, 1): 'Dia do Trabalho',
      fromEaster(60): 'Corpus Christi (facultativo)',
      DateTime(year, 9, 7): 'Independência do Brasil',
      DateTime(year, 10, 12): 'Nossa Senhora Aparecida',
      DateTime(year, 11, 2): 'Finados',
      DateTime(year, 11, 15): 'Proclamação da República',
      DateTime(year, 11, 20): 'Consciência Negra',
      DateTime(year, 12, 25): 'Natal',
    };
  });
}

final Map<int, Map<DateTime, String>> _cache = {};

/// Domingo de Páscoa (algoritmo de Meeus/Jones/Butcher).
DateTime _easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}
