import 'package:flutter/material.dart';
import '../../controllers/sign_up_controller.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../shared/themes/app_colors.dart';

class SignUpAccountTypeSelectorWidget extends StatelessWidget {
  final SignUpController controller;

  const SignUpAccountTypeSelectorWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => controller.updateAccountType('cliente'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: controller.accountType == 'cliente'
                    ? AppColors.aquaButton
                    : Colors.transparent,
                border: Border.all(
                  color: controller.accountType == 'cliente'
                      ? AppColors.aquaButton
                      : AppColors.aquaText.withAlpha(80),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: TextDefault(
                  'Cliente',
                  fontSize: 14,
                  color: controller.accountType == 'cliente'
                      ? AppColors.white
                      : AppColors.aquaText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => controller.updateAccountType('profissional'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: controller.accountType == 'profissional'
                    ? AppColors.aquaButton
                    : Colors.transparent,
                border: Border.all(
                  color: controller.accountType == 'profissional'
                      ? AppColors.aquaButton
                      : AppColors.aquaText.withAlpha(80),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: TextDefault(
                  'Profissional',
                  fontSize: 14,
                  color: controller.accountType == 'profissional'
                      ? AppColors.white
                      : AppColors.aquaText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
