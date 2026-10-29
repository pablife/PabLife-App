import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double height;

  const AppLogo({super.key, this.width = 187, this.height = 176});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/app_logo.svg',
      width: width,
      height: height,
    );
  }
}
