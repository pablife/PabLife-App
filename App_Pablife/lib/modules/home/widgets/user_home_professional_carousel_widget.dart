import 'package:flutter/material.dart';
import '../controllers/user_home_controller.dart';
import 'professional_carousel.dart';

class UserHomeProfessionalCarouselWidget extends StatelessWidget {
  final UserHomeController controller;

  const UserHomeProfessionalCarouselWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.professionals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ProfessionalCarousel(
          professionals: controller.professionals,
          currentIndex: controller.currentProfessionalIndex,
          onPageChanged: controller.changeProfessional,
        ),
      ],
    );
  }
}
