import 'package:flutter/material.dart';
import '../controllers/user_home_controller.dart';
import 'user_home_appointment_carousel_widget.dart';
import 'section_empty_state_widget.dart';
import '../../../modules/dashboard/dashboard_controller.dart';

class UserHomeAppointmentsSection extends StatelessWidget {
  final UserHomeController controller;

  const UserHomeAppointmentsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final activeAppointments = controller.activeAppointments;

    if (activeAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SectionEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Nenhuma consulta marcada',
          description:
              'Agende uma consulta na tela de profissionais e ela aparecerá aqui.',
          buttonLabel: 'Explorar profissionais',
          onAction: _handleExploreProfessionals,
          backgroundColor: const Color(0xFFF5FAFF),
        ),
      );
    }

    return UserHomeAppointmentCarouselWidget(controller: controller);
  }

  void _handleExploreProfessionals() {
    // Navega para a aba de Profissionais (index 3)
    DashboardController.to.changeTab(3);
  }
}
