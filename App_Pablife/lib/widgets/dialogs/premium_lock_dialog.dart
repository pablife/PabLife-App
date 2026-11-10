import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/profile/pages/subscription_page.dart';
import '../../shared/themes/pab_colors.dart';
import '../design_system/app_dialog.dart';

/// Aviso de recurso que pede assinatura, no visual da repaginação.
class PremiumLockDialog extends StatelessWidget {
  final String message;
  final String? contentType;
  final String? contentTitle;

  const PremiumLockDialog({
    super.key,
    required this.message,
    this.contentType,
    this.contentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final subject = [
      contentType,
      contentTitle,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().join(' · ');

    return AppDialog(
      title: 'Conteúdo bloqueado',
      icon: Icons.lock_outline_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subject.isNotEmpty) ...[
            Text(
              subject,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pabFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: PabColors.accentText,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(message),
        ],
      ),
      cancelText: 'Voltar',
      onCancel: () => Get.back<void>(),
      confirmText: 'Ver planos',
      onConfirm: () {
        Get.back<void>();
        Get.toNamed(SubscriptionPage.route);
      },
    );
  }
}
