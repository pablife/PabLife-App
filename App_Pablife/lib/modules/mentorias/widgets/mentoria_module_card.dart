import 'package:flutter/material.dart';
import '../../../infra/models/mentoria_module_model.dart';
import '../../../widgets/design_system/text_default.dart';

class MentoriaModuleCard extends StatelessWidget {
  final MentoriaModuleModel module;
  final bool isSelected;

  const MentoriaModuleCard({
    super.key,
    required this.module,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(module.colorHex);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 185,
      height: 183,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: TextDefault(
          module.title,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          maxLines: 3,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.isEmpty) {
        return const Color(0xFF00343C);
      }
      final hex = colorString.replaceAll('0x', '');
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF00343C);
    }
  }
}
