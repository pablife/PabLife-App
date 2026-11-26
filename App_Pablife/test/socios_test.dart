import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/infra/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://exemplo.supabase.co', anonKey: 'x');
  });

  tearDown(() {
    SubscriptionService.instance
      ..freeAccess = false
      ..lifetimeMember = false;
  });

  test('sócio: acesso a tudo e consultas sem limite, sem plano', () async {
    SubscriptionService.instance
      ..lifetimeMember = true
      ..freeAccess = true;
    final info = await SubscriptionService.instance.getUserAccessInfo(
      userId: 'socio',
    );
    expect(info.status, SubscriptionAccessStatus.active);
    expect(info.canScheduleAppointment, isTrue);
    expect(info.canAccessPlanner, isTrue);
    expect(info.canAccessMentorias, isTrue);
    expect(info.hasConsultationsRemaining, isTrue);
  });
}
