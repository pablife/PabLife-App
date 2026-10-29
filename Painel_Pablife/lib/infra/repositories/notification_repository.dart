import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/utils/app_snackbar.dart';
import '../models/notifications_model.dart';

class NotificationRepository extends StrautilsTryThis {
  late final SupabaseQueryBuilder _database;

  NotificationRepository({SupabaseQueryBuilder? database}) {
    _database = database ?? Supabase.instance.client.from('tb_notifications');
  }

  FStrautilsResponse<List<NotificationModel>> getNotifications() {
    return tryThis(
      () async {
        final responseData =
            await Supabase.instance.client.rpc('get_broadcast_notifications');

        if (responseData is! List) {
          throw Exception(
              'Unexpected response type from RPC: ${responseData.runtimeType}');
        }

        final notifications = (responseData as List)
            .map<NotificationModel>(
                (e) => NotificationModel.fromMap(e as Map<String, dynamic>))
            .toList();
        return StrautilsResponse.success(notifications);
      },
      onCatch: (error) {
        AppSnackbar.to.show('Erro ao buscar notificações: $error');
        return StrautilsResponse.error(
          'Erro ao buscar notificações',
          data: error,
        );
      },
    );
  }

  FStrautilsResponse<NotificationModel> createNotification(
    NotificationModel notification,
  ) {
    return tryThis(
      () async {
        final response = await _database
            .insert(notification.toMap())
            .select()
            .single();

        return StrautilsResponse.success(NotificationModel.fromMap(response));
      },
      onCatch: (error) {
        AppSnackbar.to.show('Erro ao criar notificação: $error');
        return StrautilsResponse.error(
          'Erro ao criar notificação',
          data: error,
        );
      },
    );
  }

  FStrautilsResponse<void> deleteNotification(String notificationId) {
    return tryThis(
      () async {
        await _database.delete().eq('id', notificationId);
        return StrautilsResponse.success(null);
      },
      onCatch: (error) {
        AppSnackbar.to.show('Erro ao excluir notificação: $error');
        return StrautilsResponse.error(
          'Erro ao excluir notificação',
          data: error,
        );
      },
    );
  }
}
