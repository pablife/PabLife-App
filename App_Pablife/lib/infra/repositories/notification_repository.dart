import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<NotificationModel>> getAll() {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final response = await _client
          .from('tb_notifications')
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map(
            (item) => NotificationModel.fromMap(item as Map<String, dynamic>),
          )
          .toList();

      return StrautilsResponse.success(notifications);
    }, action: 'buscar todas as notificações.');
  }

  FStrautilsResponse<bool> markAsRead(String notificationId) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final notification = await _client
          .from('tb_notifications')
          .select('user_id')
          .eq('id', notificationId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (notification == null) {
        return StrautilsResponse.error('Notificação não encontrada.');
      }

      final notificationUserId = notification['user_id'] as String?;

      if (notificationUserId == userId) {
        await _client
            .from('tb_notifications')
            .update({'read_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', notificationId)
            .eq('user_id', userId)
            .isFilter('deleted_at', null);
      } else if (notificationUserId == null) {
        await _client
            .from('tb_notifications')
            .update({'read_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', notificationId)
            .isFilter('deleted_at', null);
      } else {
        return StrautilsResponse.error('Notificação não pertence ao usuário.');
      }

      return StrautilsResponse.success(true);
    }, action: 'marcar notificação como lida.');
  }

  FStrautilsResponse<bool> markAllAsRead() {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      await _client
          .from('tb_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .isFilter('read_at', null);

      await _client
          .from('tb_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .isFilter('user_id', null)
          .isFilter('deleted_at', null)
          .isFilter('read_at', null);

      return StrautilsResponse.success(true);
    }, action: 'marcar todas as notificações como lidas.');
  }

  FStrautilsResponse<int> getUnreadCount() {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.success(0);
      }

      final response = await _client
          .from('tb_notifications')
          .select('id')
          .or('user_id.eq.$userId,user_id.is.null')
          .isFilter('deleted_at', null)
          .isFilter('read_at', null);

      final count = (response as List).length;
      return StrautilsResponse.success(count);
    }, action: 'contar notificações não lidas.');
  }

  FStrautilsResponse<bool> delete(String notificationId) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final notification = await _client
          .from('tb_notifications')
          .select('user_id')
          .eq('id', notificationId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (notification == null) {
        return StrautilsResponse.error('Notificação não encontrada.');
      }

      final notificationUserId = notification['user_id'] as String?;

      if (notificationUserId == userId) {
        await _client
            .from('tb_notifications')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', notificationId)
            .eq('user_id', userId)
            .isFilter('deleted_at', null);
      } else if (notificationUserId == null) {
        await _client
            .from('tb_notifications')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', notificationId)
            .isFilter('deleted_at', null);
      } else {
        return StrautilsResponse.error('Notificação não pertence ao usuário.');
      }

      return StrautilsResponse.success(true);
    }, action: 'deletar notificação.');
  }
}
