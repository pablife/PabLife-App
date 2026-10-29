import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/shared/controllers/layout_controller.dart';
import 'banners_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import 'widgets/banner_list_item.dart';
import 'widgets/banner_list_row.dart';

class BannersPage extends StatelessWidget {
  const BannersPage({super.key});

  static const route = '/banners';

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Banners');
    return GetBuilder<BannersController>(
      builder: (controller) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryGreen,
            onPressed: () => controller.openForm(context, controller),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              // Barra com toggle de visualização
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ViewModeToggle(
                      currentMode: controller.viewMode,
                      onModeChanged: controller.setViewMode,
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.items.isEmpty
                    ? const Center(
                        child: TextDefault(
                          text: 'Nenhum banner cadastrado',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : controller.viewMode.isGrid
                    // Grid
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          const targetCardWidth = 400.0;
                          const targetCardHeight = 400.0;
                          final columns =
                              (constraints.maxWidth / targetCardWidth)
                                  .floor()
                                  .clamp(1, 6);

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent: targetCardHeight,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: controller.items.length,
                            itemBuilder: (context, index) {
                              final b = controller.items[index];
                              return BannerListItem(
                                banner: b,
                                onToggleActive: (v) =>
                                    controller.toggleActive(b.id, v),
                                onEdit: () =>
                                    controller.openForm(context, controller, b),
                                onDelete: () => controller.delete(b.id),
                              );
                            },
                          );
                        },
                      )
                    // Lista
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.items.length,
                        itemBuilder: (context, index) {
                          final b = controller.items[index];
                          return BannerListRow(
                            banner: b,
                            onToggleActive: (v) =>
                                controller.toggleActive(b.id, v),
                            onEdit: () =>
                                controller.openForm(context, controller, b),
                            onDelete: () => controller.delete(b.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
