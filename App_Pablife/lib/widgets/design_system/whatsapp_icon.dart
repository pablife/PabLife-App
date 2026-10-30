import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo do WhatsApp (Simple Icons, CC0). Substitui o FontAwesomeIcons.whatsapp,
/// que fazia o app carregar as três fontes do Font Awesome.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/whatsapp.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
