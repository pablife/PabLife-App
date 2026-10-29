import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import 'mentorias_controller.dart';
import 'widgets/mentorias_search_field.dart';
import 'widgets/category_tabs_widget.dart';
import 'widgets/mentorias_list_widget.dart';

class MentoriasPage extends StatelessWidget {
  const MentoriasPage({super.key});

  static const route = '/mentorias';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MentoriasController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Column(
            children: [
              const SizedBox(height: 10),
              MentoriasSearchField(
                controller: controller.searchController,
                showOnlySaved: controller.showOnlySaved,
                savedCount: controller.filteredMentorias
                    .where((m) => m.isSaved)
                    .length,
                onChanged: (value) => controller.searchMentorias(value),
                onBookmarkTap: controller.toggleSavedFilter,
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
                      CategoryTabsWidget(
                        categories: controller.categories,
                        selectedCategory: controller.selectedCategory,
                        onCategorySelected: controller.changeCategory,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: MentoriasListWidget(
                          isLoading: controller.isLoading,
                          mentorias: controller.filteredMentorias,
                          showOnlySaved: controller.showOnlySaved,
                          onMentoriaTap: controller.openMentoria,
                          onBookmarkTap: controller.toggleSaveMentoria,
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
