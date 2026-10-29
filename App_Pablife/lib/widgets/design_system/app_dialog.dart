import 'package:flutter/material.dart';
import '../../shared/themes/app_colors.dart';
import 'text_default.dart';
import 'edge_button_rounded.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.second,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: AppColors.aqua,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextDefault(
              title,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 24),
            if (confirmText != null || cancelText != null)
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: EdgeButtonRounded(
                        text: cancelText!,
                        inverseRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(100),
                        ),
                        onTap:
                            onCancel ?? () => Navigator.of(context).pop(false),
                        backgroundColor:
                            cancelButtonColor ?? const Color(0xFF0C8DA1),
                      ),
                    ),
                    if (confirmText != null) const SizedBox(width: 10),
                  ],
                  if (confirmText != null)
                    Expanded(
                      child: EdgeButtonRounded(
                        side: EdgeSide.left,
                        text: confirmText!,
                        inverseRadius: BorderRadius.only(
                          bottomRight: Radius.circular(100),
                        ),
                        onTap:
                            onConfirm ?? () => Navigator.of(context).pop(true),
                        backgroundColor: confirmButtonColor ?? AppColors.second,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmButtonColor,
    Color? cancelButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextDefault(
            message,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.white.withAlpha(204),
            textAlign: TextAlign.center,
          ),
        ),
        confirmText: confirmText,
        cancelText: cancelText,
        confirmButtonColor: confirmButtonColor,
        cancelButtonColor: cancelButtonColor,
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmButtonColor,
    Color? cancelButtonColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmButtonColor: confirmButtonColor,
        cancelButtonColor: cancelButtonColor,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
