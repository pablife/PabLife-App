import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _functions = Supabase.instance.client.functions;

  Future<bool> sendNotification({
    required String title,
    required String message,
    String? appointmentId,
    String? professionalId,
    String? customerId,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'message': message,
        if (appointmentId != null) 'appointmentId': appointmentId,
        if (professionalId != null) 'professionalId': professionalId,
        if (customerId != null) 'customerId': customerId,
      };

      final response = await _functions.invoke(
        'send-notification',
        body: body,
      );

      if (response.status == 200) {
        // Sucesso
        if (kDebugMode) {
          // Imprime a informação de depuração retornada pela função
          print('DEBUG INFO from function: ${response.data}');
        }
        // Retorna true para a UI não registrar um erro durante o teste
        return true;
      } else {
        // Erro
        if (kDebugMode) {
          print(
            'Erro ao invocar função "send-notification". Status: ${response.status}, Body: ${response.data}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exceção ao invocar função: $e');
      }
      return false;
    }
  }
}
