import 'package:flutter/material.dart';

import '../../shared/themes/pab_colors.dart';

/// Janela de confirmação no visual da repaginação: cartão branco, título em
/// [PabColors.ink], botão de voltar contornado e botão de confirmar em
/// [PabColors.accent] (ou vermelho quando [destructive]).
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Ação que apaga ou cancela algo: botão de confirmar vermelho.
  final bool destructive;
  final IconData? icon;
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.destructive = false,
    this.icon,
    this.barrierDismissible = true,
  });

  /// Texto padrão do corpo da janela.
  static const messageStyle = TextStyle(
    fontFamily: pabFontFamily,
    fontSize: 15,
    height: 1.5,
    color: PabColors.muted,
  );

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Dialog(
      backgroundColor: PabColors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null || destructive) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: destructive
                        ? const Color(0xFFFBE7EB)
                        : PabColors.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.delete_outline_rounded,
                    color: destructive ? PabColors.error : PabColors.softText,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: pabFontFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              DefaultTextStyle.merge(
                style: messageStyle,
                textAlign: TextAlign.center,
                child: content,
              ),
              if (confirmText != null || cancelText != null) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (cancelText != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              onCancel ??
                              () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: PabColors.ink,
                            side: const BorderSide(color: PabColors.lineStrong),
                            shape: shape,
                          ),
                          child: Text(
                            cancelText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: pabFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (cancelText != null && confirmText != null)
                      const SizedBox(width: 10),
                    if (confirmText != null)
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              onConfirm ??
                              () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: destructive
                                ? PabColors.error
                                : PabColors.accent,
                            foregroundColor: destructive
                                ? Colors.white
                                : PabColors.ink,
                            shape: shape,
                          ),
                          child: Text(
                            confirmText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: pabFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
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
    bool destructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: Text(message),
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
        icon: icon,
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
    bool destructive = false,
    IconData? icon,
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
        destructive: destructive,
        icon: icon,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
