import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import 'bookmark_button_widget.dart';

class MentoriasSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool showOnlySaved;
  final int savedCount;
  final void Function(String) onChanged;
  final VoidCallback onBookmarkTap;

  const MentoriasSearchField({
    super.key,
    required this.controller,
    required this.showOnlySaved,
    required this.savedCount,
    required this.onChanged,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: AppTextFormField(
        hintText: 'Buscar Mentoria',
        controller: controller,
        onChanged: onChanged,
        suffixIcon: BookmarkButtonWidget(
          isActive: showOnlySaved,
          savedCount: savedCount,
          onTap: onBookmarkTap,
        ),
      ),
    );
  }
}
