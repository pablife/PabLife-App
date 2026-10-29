import 'package:flutter/material.dart';
import '../../../widgets/design_system/tabs_widget.dart';

class PatientsTabsWidget extends StatelessWidget {
  final List<String> tabs;
  final int selectedTab;
  final void Function(int) onTabSelected;

  const PatientsTabsWidget({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TabsWidget(
      tabs: tabs,
      selectedTab: tabs[selectedTab],
      onTabSelected: (tabName) {
        final index = tabs.indexOf(tabName);
        if (index != -1) {
          onTabSelected(index);
        }
      },
    );
  }
}
