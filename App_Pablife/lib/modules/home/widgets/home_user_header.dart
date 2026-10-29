import 'package:flutter/material.dart';
import 'package:pablife/infra/models/user_model.dart';
import 'package:pablife/modules/home/utils/greetings.dart';
import 'package:pablife/widgets/app_logo.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/notification_button_widget.dart';
import '../../../widgets/design_system/text_default.dart';

class HomeUserHeader extends StatelessWidget {
  final UserModel? user;
  const HomeUserHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(),
      child: Row(
        children: [
          AppLogo(width: 60, height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextDefault(
                  '${getGreetings()},',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.second,
                ),
                TextDefault(
                  user?.fullName ?? 'Usuário',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.second,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const NotificationButtonWidget(),
        ],
      ),
    );
  }
}
