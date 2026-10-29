import 'package:flutter/material.dart';
import '../../controllers/sign_up_controller.dart';
import '../../../../shared/themes/app_colors.dart';

class SignUpTermsCheckboxWidget extends StatelessWidget {
  final SignUpController controller;

  const SignUpTermsCheckboxWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: controller.termsAccepted,
          onChanged: (value) => controller.updateTermsAccepted(value ?? false),
          activeColor: AppColors.aquaButton,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.aquaButton;
            }
            return AppColors.white;
          }),
          checkColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: AppColors.aquaText.withAlpha(80), width: 1.5),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Opacity(
              opacity: 0.56,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.aquaText,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Ao se cadastrar, você concorda com os nossos ',
                    ),
                    TextSpan(
                      text: 'Termos de Uso',
                      style: const TextStyle(
                        color: AppColors.aquaText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style: const TextStyle(
                        color: AppColors.aquaText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
