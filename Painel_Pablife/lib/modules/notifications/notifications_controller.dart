import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/infra/models/notifications_model.dart';
import 'package:painel_pablife/infra/repositories/notification_repository.dart';
import 'package:painel_pablife/infra/services/notification_service.dart';

import '../../shared/utils/app_snackbar.dart';

class NotificationsController extends GetxController {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final NotificationService _notificationService = NotificationService();
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  bool isLoading = false;
  List<NotificationModel> sentNotifications = [];

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading = true;
    update();
    final result = await _notificationRepository.getNotifications();
    if (result.success) {
      sentNotifications = result.data ?? [];
    }
    isLoading = false;
    update();
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }

  Future<void> sendNotification() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = titleController.text;
    final body = bodyController.text;

    isLoading = true;
    update();

    final success = await _notificationService.sendNotification(
      title: title,
      message: body,
    );

    isLoading = false;
    update();

    if (success) {
      await fetchNotifications();

      titleController.clear();
      bodyController.clear();
      AppSnackbar.to.success('Notificação enviada com sucesso!');
    } else {
      AppSnackbar.to.error('Falha ao enviar notificação. Tente novamente.');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    isLoading = true;
    update();

    final result = await _notificationRepository.deleteNotification(notificationId);

    isLoading = false;
    update();

    if (result.success) {
      await fetchNotifications();
      AppSnackbar.to.success('Notificação excluída com sucesso!');
    } else {
      AppSnackbar.to.error('Falha ao excluir notificação. Tente novamente.');
    }
  }
}
