import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/expandable_action_fab.dart';
import '../appointment_details_controller.dart';
import 'record_type_fab_icon_widget.dart';

class AppointmentDetailsBottomBarWidget extends StatelessWidget {
  final AppointmentDetailsController controller;

  const AppointmentDetailsBottomBarWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final actions = controller.availableRecordTypes
        .map(
          (type) => ExpandableFabAction(
            iconWidget: RecordTypeFabIconWidget(type: type),
            onTap: () => controller.onCreateRecord(type),
            backgroundColor: const Color(0xFF017D93),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (controller.shouldShowWhatsAppButton)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: controller.isFabExpanded ? 72 : 220,
              child: EdgeButtonRounded(
                text: 'Enviar Mensagem',
                onTap: controller.openWhatsApp,
                backgroundColor: const Color(0xFF00343C),
                textColor: Colors.white,
                side: EdgeSide.right,
                showText: !controller.isFabExpanded,
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 24,
                ),
                iconSpacing: 12,
              ),
            ),
          const Spacer(),
          if (controller.shouldShowAddRecordButton)
            ExpandableActionFab(
              backgroundColor: const Color(0xFF0C8DA1),
              expandedWidth: 220,
              height: 60,
              actions: actions,
              onExpandedChange: controller.onFabExpandedChanged,
            ),
        ],
      ),
    );
  }
}
