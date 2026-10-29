import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_home_controller.dart';
import '../../appointment_details/appointment_details_routes.dart';
import '../../patients/widgets/patient_tile.dart';

class UserHomeAppointmentCarouselWidget extends StatefulWidget {
  final UserHomeController controller;

  const UserHomeAppointmentCarouselWidget({
    super.key,
    required this.controller,
  });

  @override
  State<UserHomeAppointmentCarouselWidget> createState() =>
      _UserHomeAppointmentCarouselWidgetState();
}

class _UserHomeAppointmentCarouselWidgetState
    extends State<UserHomeAppointmentCarouselWidget> {
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
            patient: appointment,
            pageIndex: index,
            currentPageIndex: _currentCarouselIndex,
            totalPages: appointments.length,
            filledHour: true,
            showStatusIndicator: true,
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
}
