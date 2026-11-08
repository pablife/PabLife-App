import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../shared/themes/app_palette.dart';
import '../shared/themes/pab_colors.dart';

/// Logo da Pablife: o símbolo em degradê e o nome "pablife". [onDark] para
/// os topos escuros (abas e menu lateral).
class PabLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const PabLogo({super.key, this.size = 24, this.onDark = true});

  static const _pab = AppColor.pair(0xFFF7C3DF, 0xFFFFC2E6);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pablife',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vetor: fica nítido em qualquer tamanho (o PNG borrava pequeno).
          SvgPicture.asset(
            'assets/images/app_logo.svg',
            width: size * 1.06,
            height: size,
          ),
          SizedBox(width: size * .35),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'pab',
                  style: TextStyle(color: onDark ? _pab : PabColors.ink),
                ),
                const TextSpan(
                  text: 'life',
                  style: TextStyle(color: PabColors.accent),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: size * .8,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
        ],
      ),
    );
  }
}
