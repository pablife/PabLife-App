import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_button_default.dart';
import '../mentorship_controller.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();

    return GetBuilder<MentorshipController>(
      builder: (_) {
        final categories = controller.categories;
        return DropdownButtonFormField<String>(
          initialValue: controller.selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Categoria',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: categories.map((cat) {
            return DropdownMenuItem(value: cat.id, child: Text(cat.name));
          }).toList(),
          onChanged: (value) {
            controller.selectedCategoryId = value;
            controller.update();
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione uma categoria';
            }
            return null;
          },
        );
      },
    );
  }
}

class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.formKey,
    required this.onSave,
    required this.saveLabel,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : AppColors.primaryGreen,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const TextDefault(text: 'Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButtonDefault(
            text: saveLabel,
            onTap: () {
              if (formKey.currentState!.validate()) {
                onSave();
              }
            },
          ),
        ),
      ],
    );
  }
}
