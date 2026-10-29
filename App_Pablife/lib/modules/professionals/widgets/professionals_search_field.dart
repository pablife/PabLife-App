import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import 'clock_filter_button_widget.dart';

class ProfessionalsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool showOnlyScheduled;
  final int scheduledCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClockTap;

  const ProfessionalsSearchField({
    super.key,
    required this.controller,
    required this.showOnlyScheduled,
    required this.scheduledCount,
    required this.onChanged,
    required this.onClockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: AppTextFormField(
        hintText: 'Buscar Profissional',
        controller: controller,
        onChanged: onChanged,
        suffixIcon: ClockFilterButtonWidget(
          showOnlyScheduled: showOnlyScheduled,
          scheduledCount: scheduledCount,
          onTap: onClockTap,
        ),
      ),
    );
  }
}
