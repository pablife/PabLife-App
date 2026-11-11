import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/modules/calendar/widgets/phone_agenda_views.dart';
import 'package:pablife/modules/women_health/women_health_controller.dart';
import 'package:pablife/modules/women_health/women_health_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late WomenHealthController women;
  late DateTime start;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://exemplo.supabase.co', anonKey: 'x');
  });

  setUp(() {
    final today = DateTime.now();
    start = DateTime(today.year, today.month, today.day);
    women = WomenHealthController()
      ..trail = WomenTrail.cycle
      ..cycleLength = 28
      ..lastPeriod = start;
  });

  // Ciclo de 28 dias a partir de hoje: dia 1 = menstruação, dia 14 =
  // ovulação, dia 10 = fértil.
  DateTime day(int n) => start.add(Duration(days: n - 1));

  test('as três fases aparecem com cores diferentes', () {
    expect(cycleTintOn(women, day(1)), CycleColors.menstruationFill);
    expect(cycleTintOn(women, day(10)), CycleColors.fertileFill);
    expect(cycleTintOn(women, day(14)), CycleColors.ovulationFill);
  });

  test('cada filtro desliga só a sua fase', () {
    women.setCycleFilter(ovulation: false);
    expect(cycleTintOn(women, day(14)), isNull);
    expect(cycleTintOn(women, day(10)), CycleColors.fertileFill);
    expect(cycleTintOn(women, day(1)), CycleColors.menstruationFill);

    women.setCycleFilter(fertile: false, ovulation: true);
    expect(cycleTintOn(women, day(10)), isNull);
    expect(cycleTintOn(women, day(14)), CycleColors.ovulationFill);

    women.setCycleFilter(menstruation: false);
    expect(cycleTintOn(women, day(1)), isNull);
    expect(showsCycle(women), isTrue);

    women.setCycleFilter(ovulation: false);
    expect(showsCycle(women), isFalse);
  });

  test('a faixa da agenda segue os filtros', () {
    expect(women.bandOn(day(14))?.label, 'Ovulação');
    women.setCycleFilter(ovulation: false);
    expect(women.bandOn(day(14)), isNull);
    expect(women.bandOn(day(1))?.label, 'Menstruação');
  });
}
