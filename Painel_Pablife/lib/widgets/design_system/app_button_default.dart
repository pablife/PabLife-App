import 'package:flutter/material.dart';
import '../../shared/themes/app_colors.dart';

class AppButtonDefault extends StatelessWidget {
  const AppButtonDefault({
    super.key,
    required this.text,
    required this.onTap,
    this.isValid = true,
    this.isLoading = false,
    this.buttonColor = AppColors.primaryGreen,
    this.textColor = AppColors.white,
    this.borderColor,
    this.paddingVertical = 12,
    this.fontSize = 16,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isValid;
  final bool isLoading;
  final Color buttonColor;
  final Color textColor;
  final Color? borderColor;
  final double paddingVertical;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isValid && !isLoading ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: paddingVertical,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
              text,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
    );
  }
}
