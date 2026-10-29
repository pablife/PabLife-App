import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'cancelled_subscriptions_controller.dart';

class CancelledSubscriptionsPage extends StatelessWidget {
  const CancelledSubscriptionsPage({super.key});

  static const route = '/subscriptions/cancelled';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Assinaturas Canceladas');

    return GetBuilder<CancelledSubscriptionsController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: AppWidgetLoading()));
        }

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // Header com informações
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.cancel_outlined,
                                color: AppColors.error,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const TextDefault(
                                    text: 'Usuários com Assinaturas Canceladas',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: 4),
                                  TextDefault(
                                    text:
                                        '${controller.users.length} usuário(s) encontrado(s)',
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista de usuários
                  if (controller.users.isEmpty)
                    const Expanded(
                      child: Center(
                        child: TextDefault(
                          text: 'Nenhum usuário com assinatura cancelada',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.users.length,
                        itemBuilder: (context, index) {
                          final userSub = controller.users[index];
                          final user = userSub['user'];
                          final subscription = userSub['subscription'];
                          final plan = subscription['plan'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.error,
                                child: Text(
                                  user['full_name'][0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: TextDefault(
                                text: user['full_name'],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  TextDefault(
                                    text: user['email'],
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  TextDefault(
                                    text: 'Plano: ${plan['reason'] ?? 'N/A'}',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  if (subscription['cancelled_at'] != null)
                                    TextDefault(
                                      text:
                                          'Cancelado em: ${_formatDate(subscription['cancelled_at'])}',
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const TextDefault(
                                  text: 'Cancelada',
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
