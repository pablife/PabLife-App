import 'package:flutter/material.dart';
import '../../../widgets/design_system/tabs_widget.dart';

class ProfessionalTabsWidget extends StatelessWidget {
  final List<String> types;
  final String selectedType;
  final void Function(String) onTypeSelected;

  const ProfessionalTabsWidget({
    super.key,
    required this.types,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TabsWidget(
      tabs: types,
      selectedTab: selectedType,
      onTabSelected: onTypeSelected,
    );
  }
}
