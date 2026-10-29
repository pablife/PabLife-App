import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/app_button_default.dart';
import '../../widgets/design_system/empty_state_widget.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import '../../widgets/design_system/tabs_widget.dart';
import '../patients/widgets/patient_tile.dart';
import 'appointment_details_controller.dart';
import 'widgets/appointment_details_bottom_bar_widget.dart';
import 'widgets/record_card.dart';

class AppointmentDetailsPage extends StatelessWidget {
  const AppointmentDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppointmentDetailsController>(
      builder: (controller) {
        // Show loading during initial appointment fetch
        if (controller.isLoadingAppointment || controller.appointment == null) {
          return Scaffold(
            extendBody: true,
            backgroundColor: const Color(0xFF00343C),
            appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
            body: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFC1CDFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(39),
                  topRight: Radius.circular(39),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF00343C)),
              ),
            ),
          );
        }

        // Local non-nullable reference for convenience
        final appointment = controller.appointment!;

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PatientTile(
                          isProfessional: controller.isPatient == false,
                          showStatusIndicator: true,
                          patient: appointment,
                          customButtonColor: controller.shouldShowCancelButton
                              ? const Color(0xFFC1CDFF)
                              : const Color(0xFF0C8DA1),
                          customTimeColor: const Color(0xFF0C8DA1),
                          customTrailingIcon: controller.canShowCompleteButton
                              ? Icons.check
                              : appointment.status ==
                                        AppointmentStatus.scheduled &&
                                    appointment.startedAt == null &&
                                    controller.shouldShowCancelButton
                              ? Icons.event_busy
                              : null,
                          customTrailingIconColor:
                              controller.canShowCompleteButton
                              ? const Color(0xFF0C8DA1)
                              : Colors.black,
                          onTrailingTap: controller.canShowCompleteButton
                              ? controller.completeAppointment
                              : appointment.status ==
                                        AppointmentStatus.scheduled &&
                                    appointment.startedAt == null &&
                                    controller.shouldShowCancelButton
                              ? controller.promptCancelAppointment
                              : null,
                          forceShowTrailing: controller.canShowCompleteButton,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Content area - tabs/records, action buttons, or status message
                      if ((appointment.status == AppointmentStatus.scheduled &&
                              appointment.startedAt != null) ||
                          appointment.status ==
                              AppointmentStatus.completed) ...[
                        if (controller.tabs.isNotEmpty)
                          TabsWidget(
                            tabs: controller.tabs,
                            selectedTab: controller.currentTab,
                            onTabSelected: controller.changeTab,
                          ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: controller.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00343C),
                                  ),
                                )
                              : controller.filteredRecords.isEmpty
                              ? const EmptyStateWidget(
                                  icon: Icons.description_outlined,
                                  title: 'Nenhum registro encontrado',
                                  description:
                                      'Os registros deste tipo aparecerão aqui',
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    90,
                                  ),
                                  itemCount: controller.filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record =
                                        controller.filteredRecords[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: RecordCard(record: record),
                                    );
                                  },
                                ),
                        ),
                      ] else if (appointment.status ==
                              AppointmentStatus.scheduled &&
                          appointment.startedAt == null)
                        // Show status and action buttons for scheduled appointments that haven't started
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getScheduledStatusIcon(),
                                    size: 80,
                                    color: AppColors.aquaText,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _getScheduledStatusTitle(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF00343C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getScheduledStatusDescription(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF00343C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  if (controller.canShowStartButton ||
                                      controller.canShowNoShowButton)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (controller.canShowStartButton)
                                          Expanded(
                                            child: AppButtonDefault(
                                              text: 'Começar',
                                              onTap:
                                                  controller.startAppointment,
                                              backgroundColor: const Color(
                                                0xFF0C8DA1,
                                              ),
                                            ),
                                          ),
                                        if (controller.canShowStartButton &&
                                            controller.canShowNoShowButton)
                                          const SizedBox(width: 8),
                                        if (controller.canShowNoShowButton)
                                          Expanded(
                                            child: AppButtonDefault(
                                              text: 'Não compareceu',
                                              onTap: controller.markNoShow,
                                              backgroundColor:
                                                  Colors.orangeAccent,
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        // Show status message for cancelled, completed, or no_show
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getStatusIcon(appointment.status),
                                    size: 80,
                                    color: AppColors.aquaText,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _getStatusMessage(appointment.status),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF00343C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getStatusDescription(appointment.status),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF00343C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppointmentDetailsBottomBarWidget(
            controller: controller,
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.cancelled:
        return Icons.event_busy;
      case AppointmentStatus.completed:
        return Icons.check_circle_outline;
      case AppointmentStatus.noShow:
        return Icons.person_off_outlined;
      case AppointmentStatus.scheduled:
        return Icons.event_available;
    }
  }

  String _getStatusMessage(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.cancelled:
        return 'Consulta Cancelada';
      case AppointmentStatus.completed:
        return 'Consulta Concluída';
      case AppointmentStatus.noShow:
        return 'Não Compareceu';
      case AppointmentStatus.scheduled:
        return 'Agendada';
    }
  }

  String _getStatusDescription(AppointmentStatus status) {
    final controller = Get.find<AppointmentDetailsController>();
    switch (status) {
      case AppointmentStatus.cancelled:
        return 'Esta consulta foi cancelada e não possui registros.';
      case AppointmentStatus.completed:
        return 'Esta consulta foi concluída.';
      case AppointmentStatus.noShow:
        return controller.isPatient
            ? 'Você não compareceu a esta consulta.'
            : 'O paciente não compareceu a esta consulta.';
      case AppointmentStatus.scheduled:
        return 'Consulta agendada.';
    }
  }

  IconData _getScheduledStatusIcon() {
    final controller = Get.find<AppointmentDetailsController>();
    final now = DateTime.now();
    final tenMinutesBefore = controller.appointment!.startAt.subtract(
      const Duration(minutes: 10),
    );
    final tenMinutesAfter = controller.appointment!.startAt.add(
      const Duration(minutes: 10),
    );

    if (now.isBefore(tenMinutesBefore)) {
      return Icons.event_available;
    } else if (now.isAfter(tenMinutesAfter)) {
      return Icons.schedule;
    } else {
      return Icons.access_time;
    }
  }

  String _getScheduledStatusTitle() {
    final controller = Get.find<AppointmentDetailsController>();
    final now = DateTime.now();
    final tenMinutesBefore = controller.appointment!.startAt.subtract(
      const Duration(minutes: 10),
    );
    final tenMinutesAfter = controller.appointment!.startAt.add(
      const Duration(minutes: 10),
    );

    if (now.isBefore(tenMinutesBefore)) {
      return 'Consulta Agendada';
    } else if (now.isBefore(controller.appointment!.startAt)) {
      return 'Consulta Prestes a Começar';
    } else if (now.isBefore(tenMinutesAfter)) {
      return 'Horário da Consulta';
    } else {
      return controller.isPatient
          ? 'Aguardando Profissional'
          : 'Consulta Atrasada';
    }
  }

  String _getScheduledStatusDescription() {
    final controller = Get.find<AppointmentDetailsController>();
    final now = DateTime.now();
    final tenMinutesBefore = controller.appointment!.startAt.subtract(
      const Duration(minutes: 10),
    );
    final tenMinutesAfter = controller.appointment!.startAt.add(
      const Duration(minutes: 10),
    );

    if (now.isBefore(tenMinutesBefore)) {
      final formattedDate = controller.appointment!.formattedTime;
      return 'A consulta está agendada para $formattedDate.\nAguarde o horário para iniciar.';
    } else if (now.isBefore(controller.appointment!.startAt)) {
      final difference = controller.appointment!.startAt.difference(now);
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      return 'Aguarde mais ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (now.isBefore(tenMinutesAfter)) {
      return controller.isPatient
          ? 'O horário da consulta chegou.\nAguarde o profissional iniciar.'
          : 'O horário da consulta chegou.\nAguarde o paciente para começar.';
    } else {
      return controller.isPatient
          ? 'O profissional ainda não iniciou a consulta.\nAguarde mais um pouco.'
          : 'Caso o paciente não compareça,\nmarque que não compareceu.';
    }
  }
}
