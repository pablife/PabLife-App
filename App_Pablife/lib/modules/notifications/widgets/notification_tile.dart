import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/notification_model.dart';
import '../../../shared/themes/pab_colors.dart';
import '../notifications_page.dart';

/// Cartão de uma notificação: ícone do assunto, texto, hora e o ponto rosa
/// enquanto não foi lida. Arrastar para a esquerda apaga.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  static String formatTime(DateTime date, {DateTime? now}) {
    final local = date.toLocal();
    final current = now ?? DateTime.now();
    final days = DateUtils.dateOnly(
      current,
    ).difference(DateUtils.dateOnly(local)).inDays;
    if (days == 0) return DateFormat('HH:mm').format(local);
    if (days == 1) return 'Ontem';
    if (days < 7) {
      return const [
        'Dom',
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
      ][local.weekday % 7];
    }
    return DateFormat('dd/MM/yyyy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final look = notificationLook(notification);
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: PabColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Material(
          color: unread ? PabColors.card : const Color(0xFFF9FBFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PabColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: look.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(look.icon, size: 20, color: look.foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notification.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF2E4446),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatTime(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unread ? PabColors.pink : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
