import 'package:flutter/material.dart';
import '../../../widgets/design_system/tabs_widget.dart';

class CategoryTabsWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final void Function(String) onCategorySelected;

  const CategoryTabsWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return TabsWidget(
      tabs: categories,
      selectedTab: selectedCategory,
      onTabSelected: onCategorySelected,
    );
  }
}
