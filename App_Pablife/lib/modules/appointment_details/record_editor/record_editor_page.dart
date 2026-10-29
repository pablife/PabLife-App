import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'record_editor_controller.dart';
import 'widgets/record_editor_bottom_bar_widget.dart';
import 'widgets/record_editor_content_widget.dart';
import 'widgets/record_editor_header_widget.dart';

class RecordEditorPage extends StatelessWidget {
  const RecordEditorPage({super.key});

  static const route = '/appointment/record-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecordEditorController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: Column(
            children: [
              const SizedBox(height: 32),
              RecordEditorHeaderWidget(controller: controller),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(39),
                    topRight: Radius.circular(39),
                  ),
                  child: RecordEditorContentWidget(controller: controller),
                ),
              ),
              RecordEditorBottomBarWidget(controller: controller),
            ],
          ),
        );
      },
    );
  }
}
