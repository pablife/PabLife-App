import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';
import '../../widgets/design_system/view_mode_toggle.dart';
import '../../widgets/states/app_widget_loading.dart';
import 'users_controller.dart';
import 'widgets/pagination_widget.dart';
import 'widgets/search_field.dart';
import 'widgets/user_card_item.dart';
import 'widgets/user_details_modal.dart';
import 'widgets/user_list_item.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  static const route = '/users';

  @override
  Widget build(BuildContext context) {
    // Atualiza o título da página
    Get.find<LayoutController>().updateTitle('Gerenciar Usuários');

    return GetBuilder<UsersController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: AppWidgetLoading()));
        }

        return Scaffold(
          body: Column(
            children: [
              // Barra de pesquisa e toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: SearchField(controller: controller)),
                    const SizedBox(width: 16),
                    // Filtro de usuários com plano
                    FilterChip(
                      label: const TextDefault(
                        text: 'Apenas com plano',
                        fontSize: 14,
                      ),
                      selected: controller.filterOnlyWithPlan,
                      onSelected: (_) => controller.togglePlanFilter(),
                      selectedColor: AppColors.primaryGreen.withValues(
                        alpha: 0.2,
                      ),
                      checkmarkColor: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    ViewModeToggle(
                      currentMode: controller.viewMode,
                      onModeChanged: controller.setViewMode,
                    ),
                  ],
                ),
              ),

              // Conteúdo
              if (controller.filteredUsers.isEmpty)
                Expanded(
                  child: Center(
                    child: TextDefault(
                      text: 'Nenhum usuário encontrado',
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
                            ? _buildGridView(controller, context)
                            : _buildListView(controller, context),
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

  Widget _buildGridView(UsersController controller, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const targetCardWidth = 320.0;
        const targetCardHeight = 260.0;
        final columns = (constraints.maxWidth / targetCardWidth).floor().clamp(
          1,
          6,
        );

        final users = controller.filteredUsers;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: targetCardHeight,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return UserCardItem(
              user: user,
              onViewDetails: () => _showUserDetails(context, controller, user),
              onToggleStatus: () => controller.toggleUserStatus(user),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(UsersController controller, BuildContext context) {
    final users = controller.filteredUsers;

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        final user = users[index];
        return UserListItem(
          user: user,
          onTap: () => _showUserDetails(context, controller, user),
        );
      },
    );
  }

  void _showUserDetails(
    BuildContext context,
    UsersController controller,
    user,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => UserDetailsModal(
        user: user,
        onToggleStatus: () {
          Navigator.pop(context);
          controller.toggleUserStatus(user);
        },
      ),
    );
  }
}
