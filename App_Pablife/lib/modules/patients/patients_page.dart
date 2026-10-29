import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import 'patients_controller.dart';
import 'widgets/patients_search_field.dart';
import 'widgets/patients_tabs_widget.dart';
import 'widgets/patients_list_widget.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  static const route = '/patients';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PatientsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 10),
              PatientsSearchField(
                controller: controller.searchController,
                onChanged: (value) => controller.onSearchChanged(value),
              ),
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
                      const SizedBox(height: 18),
                      PatientsTabsWidget(
                        tabs: controller.tabs,
                        selectedTab: controller.currentTab,
                        onTabSelected: controller.changeTab,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PatientsListWidget(
                          isLoading: controller.isLoading,
                          patients: controller.filteredPatients,
                          onMarkAsCompleted: controller.markAsCompleted,
                          onCancelAppointment: controller.cancelAppointment,
                          onPatientTap: controller.navigateToAppointmentDetails,
                          onReschedule: controller.onReschedule,
                        ),
                      ),
                    ],
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
