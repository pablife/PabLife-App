import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_text_form_field.dart';

class PatientsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const PatientsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: AppTextFormField(
        hintText: 'Buscar paciente',
        controller: controller,
        onChanged: onChanged,
      ),
    );
  }
}
