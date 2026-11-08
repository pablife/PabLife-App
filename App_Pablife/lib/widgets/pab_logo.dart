import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../shared/themes/app_palette.dart';

/// Logo da Pablife: o símbolo e o nome "pablife", os dois em vetor (do
/// arquivo da marca), para ficarem nítidos em qualquer tela.
class PabLogo extends StatelessWidget {
  final double size;

  const PabLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pablife',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/app_logo.svg',
            width: size * 1.06,
            height: size,
          ),
          SizedBox(width: size * .35),
          // Nome da marca; no visual Saúde da Mulher o "life" fica rosa.
          SvgPicture.asset(
            'assets/pages/onboarding/app_name.svg',
            height: size * .95,
            colorMapper: AppPalette.isRose ? const _RoseName() : null,
          ),
        ],
      ),
    );
  }
}

class _RoseName extends ColorMapper {
  const _RoseName();

  static const _teal = Color(0xFF0C8DA1);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => color.toARGB32() == _teal.toARGB32() ? const Color(0xFFFF8ECF) : color;
}
