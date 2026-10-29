import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';

import '../../infra/models/appointment_model.dart';
import '../../infra/models/professional_model.dart';
import '../../infra/models/user_model.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/app_text_form_field.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'appointments_controller.dart';
import 'widgets/pagination_widget.dart';
import 'widgets/appointment_card_item.dart';
import 'widgets/appointment_list_item.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  static const route = '/appointments';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Agendamentos');
    return GetBuilder<AppointmentsController>(
      builder: (controller) {
        return Scaffold(
          body: controller.isLoading
              ? const AppWidgetLoading()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Linha 1: Profissional + Período
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  initialValue: controller.professionalFilterId,
                                  decoration: const InputDecoration(
                                    labelText: 'Profissional',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: <DropdownMenuItem<String?>>[
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Todos'),
                                    ),
                                    ...controller.professionalsMap.values.map(
                                      (p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text(
                                          p.type.isNotEmpty
                                              ? '${p.type} - ${p.id.substring(0, 6)}'
                                              : p.id.substring(0, 6),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      controller.setProfessionalFilter(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickDateRange(context, controller),
                                  icon: Icon(
                                    Icons.date_range,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.white
                                        : AppColors.aqua,
                                  ),
                                  label: TextDefault(
                                    text: controller.dateRange == null
                                        ? 'Período'
                                        : '${controller.dateRange!.start.day.toString().padLeft(2, '0')}/${controller.dateRange!.start.month.toString().padLeft(2, '0')} - ${controller.dateRange!.end.day.toString().padLeft(2, '0')}/${controller.dateRange!.end.month.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Linha 2: Cliente
                          AppTextFormField(
                            controller: controller.clientSearchController,
                            hintText: 'Cliente: nome ou e-mail',
                            suffixIcon: const Icon(Icons.search),
                          ),

                          const SizedBox(height: 12),

                          // View Mode Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ViewModeToggle(
                                currentMode: controller.viewMode,
                                onModeChanged: controller.setViewMode,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: controller.filtered.isEmpty
                          ? const Center(
                              child: TextDefault(
                                text: 'Nenhum agendamento encontrado',
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: controller.viewMode.isGrid
                                      // Grid
                                      ? LayoutBuilder(
                                          builder: (context, constraints) {
                                            const targetCardWidth = 340.0;
                                            const targetCardHeight = 260.0;
                                            final columns =
                                                (constraints.maxWidth /
                                                        targetCardWidth)
                                                    .floor()
                                                    .clamp(1, 6);

                                            return GridView.builder(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: columns,
                                                    mainAxisExtent:
                                                        targetCardHeight,
                                                    crossAxisSpacing: 16,
                                                    mainAxisSpacing: 16,
                                                  ),
                                              itemCount: controller
                                                  .paginatedFiltered
                                                  .length,
                                              itemBuilder: (context, index) {
                                                final a = controller
                                                    .paginatedFiltered[index];
                                                final pro = controller
                                                    .getProfessional(
                                                      a.professionalId,
                                                    );
                                                final user = controller.getUser(
                                                  a.scheduledBy,
                                                );

                                                return AppointmentCardItem(
                                                  appointment: a,
                                                  professional: pro,
                                                  user: user,
                                                  formatDate:
                                                      controller.formatDate,
                                                  onTap: () => _showDetails(
                                                    context,
                                                    controller,
                                                    a,
                                                    pro,
                                                    user,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          itemCount: controller
                                              .paginatedFiltered
                                              .length,
                                          itemBuilder: (context, index) {
                                            final a = controller
                                                .paginatedFiltered[index];
                                            final pro = controller
                                                .getProfessional(
                                                  a.professionalId,
                                                );
                                            final user = controller.getUser(
                                              a.scheduledBy,
                                            );

                                            return AppointmentListItem(
                                              appointment: a,
                                              professional: pro,
                                              user: user,
                                              formatDate: controller.formatDate,
                                              onTap: () => _showDetails(
                                                context,
                                                controller,
                                                a,
                                                pro,
                                                user,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                PaginationWidget(controller: controller),
                              ],
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    AppointmentsController controller,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: controller.dateRange,
    );
    if (range != null) {
      controller.setDateRange(range);
    }
  }

  void _showDetails(
    BuildContext context,
    AppointmentsController controller,
    AppointmentModel a,
    ProfessionalModel? pro,
    UserModel? user,
  ) {
    var professionalData =
        '${pro?.name != null ? '${pro?.name} - ' : ''}'
        '${pro?.translatedType ?? a.professionalId}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextDefault(
                  text: 'Detalhes do Agendamento',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 12),
                _row('Cliente', user?.fullName ?? a.scheduledBy),
                _row('E-mail', user?.email ?? '-'),
                const Divider(),
                _row('Profissional', professionalData),
                _row('Status', a.displayStatus),
                _row('Início', controller.formatDate(a.startOfScheduledWindow)),
                _row('Fim', controller.formatDate(a.endOfScheduledWindow)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextDefault(
            text: label,
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 2),
          TextDefault(text: value, fontSize: 14),
        ],
      ),
    );
  }
}
