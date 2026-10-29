import 'package:flutter/material.dart';
import '../../shared/themes/app_colors.dart';

class TextDefault extends StatelessWidget {
  const TextDefault({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.textPrimary,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Se a cor padrão (textPrimary) for usada, aplicamos lógica adaptativa
    // para garantir contraste no dark mode.
    Color effectiveColor;
    if (color == AppColors.textPrimary) {
      effectiveColor = theme.brightness == Brightness.dark
          ? AppColors.white
          : theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    } else if (color == AppColors.textSecondary) {
      // Mapeia secundário para o valor do tema (mais claro no dark)
      effectiveColor = theme.textTheme.bodyMedium?.color ?? color;
    } else {
      effectiveColor = color;
    }

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
      ),
    );
  }
}
