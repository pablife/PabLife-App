import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_model.dart';
import '../../infra/models/user_model.dart';
import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/app_text_form_field.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'professionals_controller.dart';
import 'widgets/pagination_widget.dart';
import 'widgets/professional_card_item.dart';
import 'widgets/professional_details_modal.dart';
import 'widgets/professional_list_item.dart';

class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  static const route = '/professionals';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfessionalsController>();
    Get.find<LayoutController>().updateTitle('Gerenciar Profissionais');

    return GetBuilder<ProfessionalsController>(
      builder: (_) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: AppWidgetLoading()));
        }

        return Scaffold(
          body: Column(
            children: [
              // Barra de pesquisa e filtros
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppTextFormField(
                      controller: controller.searchController,
                      hintText: 'Pesquisar por nome ou email',
                      suffixIcon: const Icon(Icons.search),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          activeColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.white
                              : AppColors.primaryGreen,
                          value: controller.showPendingOnly,
                          onChanged: (value) =>
                              controller.togglePendingFilter(),
                        ),
                        const Expanded(
                          child: TextDefault(
                            text: 'Mostrar apenas pendentes e rejeitados',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ViewModeToggle(
                          currentMode: controller.viewMode,
                          onModeChanged: controller.setViewMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Conteúdo
              if (controller.filteredProfessionals.isEmpty)
                Expanded(
                  child: Center(
                    child: TextDefault(
                      text: 'Nenhum profissional encontrado',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: controller.viewMode.isGrid
                            ? _buildGridView(controller)
                            : _buildListView(controller),
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

  Widget _buildGridView(ProfessionalsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const targetCardWidth = 320.0;
        const targetCardHeight = 280.0;
        final columns = (constraints.maxWidth / targetCardWidth).floor().clamp(
          1,
          6,
        );

        final items = controller.filteredProfessionals;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: targetCardHeight,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ProfessionalCardItem(
              item: item,
              onTap: () => _showProfessionalDetails(context, controller, item),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(ProfessionalsController controller) {
    final items = controller.filteredProfessionals;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final professional = item['professional'] as ProfessionalModel;
        final user = item['user'];

        return ProfessionalListItem(
          professional: professional,
          user: user,
          onTap: () => _showProfessionalDetails(context, controller, item),
          onToggleStatus: () =>
              controller.toggleUserStatus(user.id, user.status),
        );
      },
    );
  }

  void _showProfessionalDetails(
    BuildContext context,
    ProfessionalsController controller,
    Map<String, dynamic> item,
  ) {
    final professional = item['professional'] as ProfessionalModel;
    final user = item['user'] as UserModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          ProfessionalDetailsModal(professional: professional, user: user),
    );
  }
}
