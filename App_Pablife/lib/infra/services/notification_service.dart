import 'package:get/get.dart';
import '../repositories/notification_repository.dart';

class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  final NotificationRepository _repository = NotificationRepository();

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;

  Future<void> loadUnreadCount() async {
    if (_isLoading) return;

    _isLoading = true;
    try {
      final response = await _repository.getUnreadCount();
      if (response.success) {
        _unreadCount = response.data ?? 0;
        update(['notification_count']);
      }
    } finally {
      _isLoading = false;
    }
  }

  void incrementUnreadCount() {
    _unreadCount++;
    update(['notification_count']);
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      update(['notification_count']);
    }
  }

  void setUnreadCount(int count) {
    _unreadCount = count;
    update(['notification_count']);
  }

  @override
  Future<void> refresh() async {
    await loadUnreadCount();
  }
}
