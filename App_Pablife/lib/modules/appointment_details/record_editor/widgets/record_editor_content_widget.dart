import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/design_system/app_text_form_field.dart';
import '../../record_editor/record_editor_controller.dart';

class RecordEditorContentWidget extends StatelessWidget {
  final RecordEditorController controller;

  const RecordEditorContentWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const AppColor(0xFFC1CDFF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          children: [
            AppTextFormField(
              hintText: 'Título',
              controller: controller.titleController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 15),
            AppTextFormField(
              hintText: 'Texto',
              controller: controller.descriptionController,
              keyboardType: TextInputType.multiline,
              maxLines: 15,
              minLines: 12,
            ),
            const SizedBox(height: 15),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: SwitchListTile(
                value: controller.isShared,
                onChanged: controller.isLoading ? null : controller.setShared,
                title: const Text(
                  'Compartilhar com o paciente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  controller.isShared
                      ? 'O paciente vê este registro.'
                      : 'Privado: só você vê este registro.',
                ),
                secondary: Icon(
                  controller.isShared ? Icons.visibility : Icons.lock_outline,
                ),
              ),
            ),
            if (controller.isEditing) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: controller.isLoading
                    ? null
                    : controller.deleteRecord,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Excluir',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
