import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class AppTextVector extends StatelessWidget {
  final double width;
  final double height;

  const AppTextVector({super.key, this.width = 234, this.height = 71});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/pages/onboarding/app_name.svg',
      width: width,
      height: height,
    );
  }
}
