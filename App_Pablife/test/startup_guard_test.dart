import 'package:flutter_test/flutter_test.dart';
import 'package:pablife/shared/utils/startup_guard.dart';

void main() {
  tearDown(() => StartupGuard.passedSplash = false);

  test('abrir o site direto no cadastro manda primeiro para a Splash', () {
    final guard = StartupGuard('/splash');
    expect(guard.redirect('/auth/professional-profile')?.name, '/splash');
    expect(guard.redirect('/auth/signup')?.name, '/splash');
  });

  test('a própria Splash não é redirecionada', () {
    expect(StartupGuard('/splash').redirect('/splash'), isNull);
  });

  test('depois da Splash, a navegação segue normal', () {
    StartupGuard.passedSplash = true;
    expect(StartupGuard('/splash').redirect('/auth/signup'), isNull);
  });
}
