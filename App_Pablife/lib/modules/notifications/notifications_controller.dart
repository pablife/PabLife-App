import 'dart:async';
import 'package:get/get.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../infra/repositories/notification_repository.dart';
import '../../infra/models/notification_model.dart';
import '../../infra/services/notification_service.dart';

class NotificationsController extends GetxController with LoaderManagerMixin {
  final NotificationRepository _repository;
  final NotificationService _notificationService = NotificationService.instance;

  NotificationsController(this._repository);

  List<NotificationModel> notifications = [];
  int get unreadCount => _notificationService.unreadCount;

  Timer? _markAsReadDebounceTimer;
  final Set<String> _pendingReadNotifications = {};

  @override
  void onReady() {
    super.onReady();
    _loadInitialData();
  }

  @override
  void onClose() {
    _markAsReadDebounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    changeLoading(true);
    await loadNotifications();
    await _notificationService.loadUnreadCount();
    changeLoading(false);
  }

  Future<void> loadNotifications() async {
    final response = await _repository.getAll();
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      final loadedNotifications = response.data ?? [];

      notifications = loadedNotifications.map((notification) {
        if (_pendingReadNotifications.contains(notification.id)) {
          return notification.copyWith(
            readAt: notification.readAt ?? DateTime.now(),
          );
        }
        return notification;
      }).toList();

      update();
    }
  }

  void markAsRead(NotificationModel notification) {
    if (notification.isRead) return;

    final notificationIndex = notifications.indexWhere(
      (n) => n.id == notification.id,
    );
    if (notificationIndex != -1) {
      notifications[notificationIndex] = notification.copyWith(
        readAt: DateTime.now(),
      );

      _pendingReadNotifications.add(notification.id);

      _notificationService.decrementUnreadCount();

      update();
    }

    _markAsReadDebounceTimer?.cancel();

    _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _sendMarkAsReadToBackend(notification.id);
    });
  }

  Future<void> _sendMarkAsReadToBackend(String notificationId) async {
    try {
      final response = await _repository.markAsRead(notificationId);

      if (response.success) {
        _pendingReadNotifications.remove(notificationId);
      } else {
        _pendingReadNotifications.remove(notificationId);

        final notificationIndex = notifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (notificationIndex != -1) {
          notifications[notificationIndex] = notifications[notificationIndex]
              .copyWith(readAt: null);
          _notificationService.incrementUnreadCount();
          update();
        }

        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      _pendingReadNotifications.remove(notificationId);

      final notificationIndex = notifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (notificationIndex != -1) {
        notifications[notificationIndex] = notifications[notificationIndex]
            .copyWith(readAt: null);
        _notificationService.incrementUnreadCount();
        update();
      }

      AppSnackbar.to.show('Erro ao marcar notificação como lida.');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();

    if (unreadNotifications.isEmpty) return;

    notifications = notifications.map((notification) {
      if (!notification.isRead) {
        _pendingReadNotifications.add(notification.id);
        return notification.copyWith(readAt: DateTime.now());
      }
      return notification;
    }).toList();

    _notificationService.setUnreadCount(0);

    update();

    final response = await _repository.markAllAsRead();
    if (!response.success) {
      notifications = notifications.map((notification) {
        if (_pendingReadNotifications.contains(notification.id)) {
          return notification.copyWith(readAt: null);
        }
        return notification;
      }).toList();

      _notificationService.setUnreadCount(unreadNotifications.length);
      _pendingReadNotifications.clear();
      update();

      AppSnackbar.to.show(response.message);
    } else {
      _pendingReadNotifications.clear();
    }
  }

  Future<void> deleteNotification(NotificationModel notification) async {
    _pendingReadNotifications.remove(notification.id);

    notifications.removeWhere((n) => n.id == notification.id);

    if (!notification.isRead) {
      _notificationService.decrementUnreadCount();
    }

    update();

    final response = await _repository.delete(notification.id);
    if (!response.success) {
      notifications.add(notification);
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!notification.isRead) {
        _notificationService.incrementUnreadCount();
      }
      update();

      AppSnackbar.to.show(response.message);
    }
  }
}
