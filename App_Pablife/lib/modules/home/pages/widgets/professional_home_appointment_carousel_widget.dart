import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../infra/models/professional_appointment_model.dart';
import '../../../../shared/utils/app_snackbar.dart';
import '../../../appointment_details/appointment_details_routes.dart';
import '../../../appointment_details/widgets/reschedule_bottom_sheet.dart';
import '../../../patients/widgets/patient_tile.dart';
import '../../controllers/professional_home_controller.dart';

class ProfessionalHomeAppointmentCarouselWidget extends StatefulWidget {
  final ProfessionalHomeController controller;

  const ProfessionalHomeAppointmentCarouselWidget({
    super.key,
    required this.controller,
  });

  @override
  State<ProfessionalHomeAppointmentCarouselWidget> createState() =>
      _ProfessionalHomeAppointmentCarouselWidgetState();
}

class _ProfessionalHomeAppointmentCarouselWidgetState
    extends State<ProfessionalHomeAppointmentCarouselWidget> {
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appointments = widget.controller.activeAppointments;

    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider.builder(
      itemCount: appointments.length,
      options: CarouselOptions(
        height: 180,
        enlargeCenterPage: false,
        enableInfiniteScroll: false,
        viewportFraction: 1.0,
        aspectRatio: 2.5,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      itemBuilder: (context, index, _) {
        final appointment = appointments[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PatientTile(
            isProfessional: true,
            patient: appointment,
            pageIndex: index,
            currentPageIndex: _currentCarouselIndex,
            totalPages: appointments.length,
            filledHour: true,
            showStatusIndicator: true,
            onTrailingTap: (!appointment.isOngoing && !appointment.isCompleted)
                ? () => _onRescheduleTapped(context, appointment)
                : null,
            onTap: () {
              Get.toNamed(
                AppointmentDetailsRoutes.appointmentDetails,
                arguments: appointment.id,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onRescheduleTapped(
    BuildContext context,
    ProfessionalAppointmentModel appointment,
  ) async {
    final result = await RescheduleBottomSheet.show<String>(
      context,
      appointment,
    );

    switch (result) {
      case 'message':
        await _openWhatsApp(appointment);
        break;
      case 'confirmed':
        AppSnackbar.to.show('Consulta reagendada com sucesso!');
        break;
      case 'cancelled':
        break;
      default:
        break;
    }
  }

  Future<void> _openWhatsApp(ProfessionalAppointmentModel appointment) async {
    final rawPhone = appointment.patientPhone;
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      AppSnackbar.to.show('Paciente não possui telefone cadastrado.');
      return;
    }

    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      AppSnackbar.to.show('Telefone do paciente é inválido.');
      return;
    }
    final whatsappPhone = cleanPhone.startsWith('55')
        ? cleanPhone
        : '55$cleanPhone';

    final uri = Uri.parse('https://wa.me/$whatsappPhone');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppSnackbar.to.show('Não foi possível abrir o WhatsApp.');
    }
  }
}
