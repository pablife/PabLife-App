import 'package:flutter/material.dart';

class RescheduleBottomSheetAvatarWidget extends StatelessWidget {
  final String? patientImageUrl;

  const RescheduleBottomSheetAvatarWidget({super.key, this.patientImageUrl});

  @override
  Widget build(BuildContext context) {
    if (patientImageUrl != null && patientImageUrl!.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(patientImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00343C).withAlpha(51),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: const Color(0xFF00343C).withAlpha(128),
      ),
    );
  }
}
