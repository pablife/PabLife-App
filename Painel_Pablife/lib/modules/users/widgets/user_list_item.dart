import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../users_controller.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserListItem({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    final subscription = controller.getUserSubscription(user);
    final hasPlan = subscription != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen,
          child: Text(
            user.fullName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: TextDefault(
          text: user.fullName,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TextDefault(
              text: user.email,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            if (hasPlan) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.card_membership_outlined,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  TextDefault(
                    text:
                        subscription['tb_subscription_plans']['reason'] ??
                        'Plano',
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildStatusBadge(user.status),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    final isActive = status == UserStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextDefault(
        text: status.displayName,
        fontSize: 12,
        color: isActive ? AppColors.success : AppColors.warning,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
