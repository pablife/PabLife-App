import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/app_button_default.dart';
import 'package:painel_pablife/widgets/design_system/app_text_form_field.dart';
import 'package:painel_pablife/widgets/design_system/confirm_dialog.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

import './notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const route = '/notifications';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Enviar Notificações');

    return GetBuilder<NotificationsController>(
      builder: (controller) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              if (isMobile) {
                return _buildSingleColumnLayout(controller, context);
              }
              return _buildTwoColumnLayout(controller, context);
            },
          ),
        );
      },
    );
  }

  Widget _buildTwoColumnLayout(
    NotificationsController controller,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
            child: _buildNotificationForm(controller, context),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: .5),
        ),
        Expanded(
          flex: 6,
          child: _buildSentNotificationsList(controller, context),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout(
    NotificationsController controller,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationForm(controller, context),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          _buildSentNotificationsList(controller, context),
        ],
      ),
    );
  }

  Widget _buildNotificationForm(
    NotificationsController controller,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Criar nova notificação',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const TextDefault(
            text:
                'A notificação será enviada para todos os usuários do aplicativo.',
          ),
          const SizedBox(height: 24),
          AppTextFormField(
            title: 'Título da notificação',
            controller: controller.titleController,
            validator: (value) =>
                (value ?? '').isEmpty ? 'O título é obrigatório' : null,
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            title: 'Mensagem',
            controller: controller.bodyController,
            maxLines: 5,
            validator: (value) =>
                (value ?? '').isEmpty ? 'A mensagem é obrigatória' : null,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: AppButtonDefault(
              text: 'Enviar Notificação',
              onTap: controller.sendNotification,
              isLoading: controller.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentNotificationsList(
    NotificationsController controller,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Histórico de Envios',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        if (controller.sentNotifications.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: TextDefault(
                  text: 'Nenhuma notificação foi enviada ainda.',
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: controller.sentNotifications.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                final notification = controller.sentNotifications[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(notification.message),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextDefault(
                        text: DateFormat(
                          'dd/MM/yy \'às\' HH:mm',
                        ).format(notification.createdAt),
                        fontSize: 12,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context: context,
                            title: 'Excluir Notificação',
                            message:
                                'Tem certeza que deseja excluir esta notificação?\n\nEsta ação não pode ser desfeita.',
                            confirmText: 'Excluir',
                            cancelText: 'Cancelar',
                            confirmColor: AppColors.error,
                            icon: Icons.delete_outline,
                          );

                          if (confirmed && notification.id != null) {
                            await controller.deleteNotification(
                              notification.id!,
                            );
                          }
                        },
                        tooltip: 'Excluir',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
      ],
    );
  }
}
