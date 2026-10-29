import 'package:flutter/material.dart';

import '../../shared/themes/app_colors.dart';

class AppOutlinedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white, width: 1),
        ),
        child: child,
      ),
    );
  }
}
