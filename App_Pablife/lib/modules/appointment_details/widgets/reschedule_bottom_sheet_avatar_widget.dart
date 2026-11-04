import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../widgets/design_system/app_image.dart';

class RescheduleBottomSheetAvatarWidget extends StatelessWidget {
  final String? patientImageUrl;

  const RescheduleBottomSheetAvatarWidget({super.key, this.patientImageUrl});

  @override
  Widget build(BuildContext context) {
    // AppImage guarda a foto em cache e reduz para o tamanho mostrado.
    return ClipOval(
      child: AppImage(
        imageUrl: patientImageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: 80,
          height: 80,
          color: const AppColor(0xFF00343C).withAlpha(51),
          child: Icon(
            Icons.person,
            size: 40,
            color: const AppColor(0xFF00343C).withAlpha(128),
          ),
        ),
      ),
    );
  }
}
