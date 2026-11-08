import 'package:flutter/material.dart';

import '../shared/themes/app_palette.dart';
import '../shared/themes/pab_colors.dart';

/// Título do topo escuro das abas. No visual Saúde da Mulher ganha a linha
/// "SAÚDE DA MULHER" em cima, como no canvas.
class PabPageTitle extends StatelessWidget {
  final String title;

  const PabPageTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (AppPalette.isRose)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              'SAÚDE DA MULHER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFFFFC2E6),
              ),
            ),
          ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PabColors.onInk,
          ),
        ),
      ],
    );
  }
}
