import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/design_system/whatsapp_icon.dart';
import 'package:pablife/widgets/design_system/app_image.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../../../widgets/design_system/notification_button_widget.dart';
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
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 20),
              // Header with Avatar and Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aquaText, width: 3),
                      ),
                      child: ClipOval(
                        child: user.imageUrl != null
                            ? AppImage(
                                imageUrl: user.imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  width: 120,
                                  height: 120,
                                  color: const Color(0xFF89BEC6),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: const Color(0xFF89BEC6),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.aquaText.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        professional.typeFormatted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.aquaText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (professional.professional.description != null &&
                            professional
                                .professional
                                .description!
                                .isNotEmpty) ...[
                          _buildSectionTitle('Sobre'),
                          const SizedBox(height: 8),
                          Text(
                            professional.professional.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (professional.hasAppointment) ...[
                          _buildSectionTitle('Sua Próxima Consulta'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event_available,
                                    color: Color(0xFF006064),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        professional.appointmentFormatted ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00343C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Agendado',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF006064),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildSectionTitle('Contato'),
                        const SizedBox(height: 12),
                        _buildContactItem(
                          icon: Icons.email_outlined,
                          text: user.email,
                          onTap: () {}, // Maybe copy to clipboard?
                        ),
                        if (user.phone.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildContactItem(
                            leading: const WhatsAppIcon(
                              size: 20,
                              color: Color(0xFF0C8DA1),
                            ),
                            text: 'Conversar no WhatsApp',
                            onTap: controller.openWhatsApp,
                            isAction: true,
                          ),
                        ],

                        const SizedBox(height: 32),

                        AppButtonDefault(
                          text: professional.hasAppointment
                              ? 'Cancelar Consulta'
                              : 'Agendar Consulta',
                          onTap: controller.handleScheduleAction,
                          backgroundColor: professional.hasAppointment
                              ? Colors.redAccent
                              : const Color(0xFF0C8DA1),
                        ),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF00343C),
      ),
    );
  }

  Widget _buildContactItem({
    IconData? icon,
    Widget? leading,
    required String text,
    VoidCallback? onTap,
    bool isAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isAction
              ? Border.all(color: const Color(0xFF0C8DA1), width: 1)
              : null,
        ),
        child: Row(
          children: [
            leading ??
                Icon(
                  icon,
                  size: 20,
                  color: isAction ? const Color(0xFF0C8DA1) : Colors.grey[600],
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isAction ? const Color(0xFF0C8DA1) : Colors.black87,
                  fontWeight: isAction ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isAction)
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF0C8DA1),
              ),
          ],
        ),
      ),
    );
  }
}
