import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'mentorship_controller.dart';
import 'mentorship_routes.dart';
import '../../shared/controllers/layout_controller.dart';
import 'widgets/pagination_widget.dart';
import 'widgets/mentorship_card_item.dart';
import 'widgets/mentorship_list_item.dart';

class MentorshipPage extends StatelessWidget {
  const MentorshipPage({super.key});

  static const route = '/mentorships';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();
    Get.find<LayoutController>().updateTitle('Gerenciar Mentorias');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () => Get.toNamed(MentorshipRoutes.mentorshipCreate),
        child: const Icon(Icons.add),
      ),
      body: GetBuilder<MentorshipController>(
        builder: (_) {
          if (controller.isLoading) {
            return const AppWidgetLoading();
          }

          final mentorships = controller.mentorships;

          if (mentorships.isEmpty) {
            return Center(
              child: TextDefault(
                text: 'Nenhuma mentoria encontrada',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            );
          }

          return Column(
            children: [
              // Barra de filtros e visualização
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Spacer(),
                    ViewModeToggle(
                      currentMode: controller.viewMode,
                      onModeChanged: controller.setViewMode,
                    ),
                  ],
                ),
              ),
              // Lista ou Grid
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
          );
        },
      ),
    );
  }

  Widget _buildGridView(MentorshipController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const targetCardWidth = 320.0;
        const targetCardHeight = 480.0;
        final columns = (constraints.maxWidth / targetCardWidth).floor().clamp(
          1,
          6,
        );
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: targetCardHeight,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.mentorships.length,
          itemBuilder: (context, index) {
            final mentorship = controller.mentorships[index];
            return MentorshipCardItem(
              mentorship: mentorship,
              onTap: () => Get.toNamed(
                MentorshipRoutes.mentorshipDetails,
                arguments: mentorship.id,
              ),
              onToggleStatus: (value) {
                controller.toggleMentorshipStatus(
                  mentorship.id,
                  mentorship.isActive,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView(MentorshipController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: controller.mentorships.length,
      itemBuilder: (context, index) {
        final mentorship = controller.mentorships[index];
        return MentorshipListItem(
          mentorship: mentorship,
          onTap: () => Get.toNamed(
            MentorshipRoutes.mentorshipDetails,
            arguments: mentorship.id,
          ),
          onToggleStatus: (value) {
            controller.toggleMentorshipStatus(
              mentorship.id,
              mentorship.isActive,
            );
          },
        );
      },
    );
  }
}
