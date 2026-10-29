import 'package:flutter/material.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:get/get.dart';

import '../../infra/services/notification_service.dart';
import '../../modules/notifications/notifications_page.dart';
import '../../shared/themes/app_colors.dart';
import 'app_outlined_button.dart';

class NotificationButtonWidget extends StatelessWidget {
  const NotificationButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<NotificationService>();

    return GetBuilder<NotificationService>(
      id: 'notification_count',
      builder: (_) {
        final notificationCount = service.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AppOutlinedButton(
              onPressed: () => Get.toNamed(NotificationsPage.route),
              child: FUI(
                RegularRounded.BELL,
                width: 21,
                color: AppColors.white,
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: -5,
                right: -5,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C8DA1),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    child: Center(
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        style: const TextStyle(
                          color: Color(0xFFF3F3F3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Instrument Sans',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
