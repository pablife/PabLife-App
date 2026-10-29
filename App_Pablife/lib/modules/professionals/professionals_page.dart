import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import 'professionals_controller.dart';
import 'widgets/professionals_search_field.dart';
import 'widgets/professional_tabs_widget.dart';
import 'widgets/professionals_list_widget.dart';

class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  static const route = '/professionals';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 10),
              ProfessionalsSearchField(
                controller: controller.searchController,
                showOnlyScheduled: controller.showOnlyScheduled,
                scheduledCount: controller.filteredProfessionals
                    .where((p) => p.hasAppointment)
                    .length,
                onChanged: (value) {},
                onClockTap: controller.toggleScheduledFilter,
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
                      ProfessionalTabsWidget(
                        types: controller.professionalTypes,
                        selectedType: controller.selectedType,
                        onTypeSelected: controller.changeType,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ProfessionalsListWidget(
                          isLoading: controller.isLoading,
                          professionals: controller.filteredProfessionals,
                          showOnlyScheduled: controller.showOnlyScheduled,
                          onProfessionalTap: controller.openProfessional,
                          onCalendarTap: controller.handleCalendarAction,
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
