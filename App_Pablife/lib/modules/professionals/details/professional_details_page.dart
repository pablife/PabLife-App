import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/notification_button_widget.dart';
import '../widgets/professional_profile_sections.dart';
import 'professional_details_controller.dart';

class ProfessionalDetailsPage extends StatelessWidget {
  const ProfessionalDetailsPage({super.key});

  static const route = '/professional-details';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalDetailsController>(
      builder: (controller) {
        final professional = controller.professional;
        final user = professional.user;

        return Scaffold(
          backgroundColor: const AppColor(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 20),
              // Header with Avatar and Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ProfessionalAvatar(imageUrl: user.imageUrl),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ProfessionalTypeChip(professional.typeFormatted),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColor(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ProfessionalProfileBody(
                      professional: professional,
                      onWhatsApp: controller.openWhatsApp,
                      onScheduleAction: controller.handleScheduleAction,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
