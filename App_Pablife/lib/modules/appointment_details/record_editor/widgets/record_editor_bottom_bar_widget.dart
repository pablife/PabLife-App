import 'package:flutter/material.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/edge_button_rounded.dart';
import '../../record_editor/record_editor_controller.dart';

class RecordEditorBottomBarWidget extends StatelessWidget {
  final RecordEditorController controller;

  const RecordEditorBottomBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: AppColors.second,
      child: Row(
        children: [
          Expanded(
            child: EdgeButtonRounded(
              text: 'Cancelar',
              onTap: controller.cancel,
              backgroundColor: const Color(0xFF0C8DA1),
              side: EdgeSide.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: EdgeButtonRounded(
              text: 'Salvar',
              onTap: controller.saveRecord,
              isLoading: controller.isLoading,
              backgroundColor: const Color(0xFF00343C),
              side: EdgeSide.left,
            ),
          ),
        ],
      ),
    );
  }
}
