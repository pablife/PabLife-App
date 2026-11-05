import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pablife/infra/services/one_signal_service.dart';

void main() {
  test('falha de rede ao agendar lembrete não vira erro', () async {
    final result = await http.runWithClient(
      () => OneSignalService.scheduleNotification(
        title: 'Lembrete',
        message: 'Consulta',
        oneSignalUserId: 'id-de-teste',
        sendAfter: DateTime.utc(2030),
      ),
      () => MockClient((_) => throw http.ClientException('bloqueado')),
    );

    expect(result, isFalse);
  });
}
