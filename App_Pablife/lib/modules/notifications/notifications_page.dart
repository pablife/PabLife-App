import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/notification_model.dart';
import '../../shared/themes/pab_colors.dart';
import 'notifications_controller.dart';
import 'widgets/notification_tile.dart';

/// Notificações (canvas "N1"): voltar, "Marcar todas como lidas" e a lista
/// por Hoje, Esta semana e Anteriores.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const route = '/notifications';

  static String _group(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date.toLocal());
    if (day == today) return 'HOJE';
    if (today.difference(day).inDays < 7) return 'ESTA SEMANA';
    return 'ANTERIORES';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      builder: (controller) {
        final items = controller.notifications;
        final hasUnread = items.any((n) => !n.isRead);

        return Scaffold(
          backgroundColor: PabColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                      child: Row(
                        children: [
                          Tooltip(
                            message: 'Voltar',
                            child: Material(
                              color: PabColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: PabColors.line),
                              ),
                              child: InkWell(
                                onTap: Get.back,
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 20,
                                    color: PabColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Notificações',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: PabColors.ink,
                                ),
                              ),
                            ),
                          ),
                          if (hasUnread)
                            TextButton(
                              onPressed: controller.markAllAsRead,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                foregroundColor: PabColors.accentText,
                              ),
                              child: const Text(
                                'Marcar todas como lidas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: controller.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: PabColors.accentText,
                              ),
                            )
                          : items.isEmpty
                          ? const _Empty()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final n = items[index];
                                final group = _group(n.createdAt);
                                final showHead =
                                    index == 0 ||
                                    _group(items[index - 1].createdAt) != group;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (showHead)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          4,
                                          index == 0 ? 0 : 8,
                                          4,
                                          8,
                                        ),
                                        child: Text(
                                          group,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: PabColors.muted,
                                          ),
                                        ),
                                      ),
                                    NotificationTile(
                                      notification: n,
                                      onTap: () => controller.markAsRead(n),
                                      onDelete: () =>
                                          controller.deleteNotification(n),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 56, color: PabColors.muted),
            SizedBox(height: 12),
            Text(
              'Nenhuma notificação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Quando houver novidade, ela aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: PabColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone e cores do aviso, pelo assunto.
({IconData icon, Color background, Color foreground}) notificationLook(
  NotificationModel n,
) {
  final text = '${n.title} ${n.message}'.toLowerCase();
  if (text.contains('pagamento') || text.contains('plano')) {
    return (
      icon: Icons.payments_outlined,
      background: const Color(0xFFFFF1D6),
      foreground: const Color(0xFF6B4A00),
    );
  }
  if (text.contains('consulta')) {
    return (
      icon: Icons.event_available,
      background: PabColors.soft,
      foreground: PabColors.softText,
    );
  }
  return (
    icon: Icons.notifications_none,
    background: PabColors.lilac,
    foreground: PabColors.lilacText,
  );
}
