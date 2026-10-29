import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/empty_state_widget.dart';
import 'notifications_controller.dart';
import 'widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const route = '/notifications';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: const AppBarDefault(title: 'Notificações'),
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFC1CDFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(39),
                topRight: Radius.circular(39),
              ),
            ),
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00343C)),
                  )
                : controller.notifications.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.notifications_none,
                    title: 'Nenhuma notificação',
                    description: 'Você não possui notificações no momento.',
                    iconSize: 64,
                    titleFontSize: 18,
                    titleFontWeight: FontWeight.w600,
                    descriptionFontSize: 14,
                    descriptionFontWeight: FontWeight.w400,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
                    itemCount: controller.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = controller.notifications[index];
                      return NotificationTile(
                        notification: notification,
                        onTap: () => controller.markAsRead(notification),
                        onDelete: () =>
                            controller.deleteNotification(notification),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
