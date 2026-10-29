import 'package:flutter/material.dart';

import '../../../../widgets/app_text_vector.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../record_editor/record_editor_controller.dart';

class RecordEditorHeaderWidget extends StatelessWidget {
  final RecordEditorController controller;

  const RecordEditorHeaderWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: controller.cancel,
                child: Container(
                  width: 66,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const AppTextVector(width: 148, height: 45),
              const SizedBox(width: 66),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF00343C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            TextDefault(
              controller.pageTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}
