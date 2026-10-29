import 'package:flutter/material.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../widgets/design_system/empty_state_widget.dart';
import 'patient_tile.dart';

class PatientsListWidget extends StatelessWidget {
  final bool isLoading;
  final List<ProfessionalAppointmentModel> patients;
  final void Function(String) onMarkAsCompleted;
  final void Function(String) onCancelAppointment;
  final void Function(ProfessionalAppointmentModel)? onPatientTap;
  final void Function(ProfessionalAppointmentModel)? onReschedule;

  const PatientsListWidget({
    super.key,
    required this.isLoading,
    required this.patients,
    required this.onMarkAsCompleted,
    required this.onCancelAppointment,
    this.onPatientTap,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00343C)),
      );
    }

    if (patients.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'Nenhum paciente encontrado',
        description: 'Consultas aparecerão aqui',
        iconSize: 64,
        titleFontSize: 18,
        titleFontWeight: FontWeight.w600,
        descriptionFontSize: 14,
        descriptionFontWeight: FontWeight.w400,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PatientTile(
            patient: patient,
            isProfessional: true,
            onMarkAsCompleted: () => onMarkAsCompleted(patient.id),
            onCancelAppointment: () => onCancelAppointment(patient.id),
            onTap: onPatientTap != null ? () => onPatientTap!(patient) : null,
            onTrailingTap: (!patient.isOngoing && !patient.isCompleted)
                ? (onReschedule != null ? () => onReschedule!(patient) : null)
                : null,
            showStatusIndicator: true,
          ),
        );
      },
    );
  }
}
