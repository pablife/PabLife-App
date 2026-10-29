import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../infra/models/patient_record_model.dart';
import '../../../widgets/design_system/text_default.dart';
import '../appointment_details_controller.dart';

class RecordCard extends StatelessWidget {
  final PatientRecordModel record;

  const RecordCard({super.key, required this.record});

  Color get _titleColor => const Color(0xFF00343C);
  Color get _iconColor => const Color(0xFF033138);
  Color get _descriptionColor => const Color(0xFF000000).withAlpha(143);

  String _typeLabel(PatientRecordType type) {
    switch (type) {
      case PatientRecordType.mealPlan:
        return 'Plano Alimentar';
      case PatientRecordType.prescription:
        return 'Receita';
      case PatientRecordType.observation:
        return 'Observação';
      case PatientRecordType.note:
        return 'Anotação';
      case PatientRecordType.reflection:
        return 'Reflexão';
      case PatientRecordType.practice:
        return 'Prática';
    }
  }

  Widget _leadingIcon(PatientRecordType type) {
    if (type == PatientRecordType.mealPlan) {
      return SvgPicture.asset(
        'assets/icons/food.svg',
        width: 30,
        height: 30,
        colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
      );
    }

    IconData icon;
    switch (type) {
      case PatientRecordType.prescription:
        icon = Symbols.prescriptions;
        break;
      case PatientRecordType.observation:
        icon = Symbols.note_alt;
        break;
      case PatientRecordType.note:
        icon = Symbols.note_stack;
        break;
      case PatientRecordType.reflection:
        icon = Symbols.neurology;
        break;
      case PatientRecordType.practice:
        icon = Symbols.assignment_ind;
        break;
      default:
        icon = Symbols.description;
    }

    return Icon(icon, size: 36, color: _iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navega para a tela de edição quando o card é clicado
        final controller = Get.find<AppointmentDetailsController>();
        controller.onEditRecord(record);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFAEBEEC),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _leadingIcon(record.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextDefault(
                        record.title,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: _titleColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TextDefault(
                        _typeLabel(record.type),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextDefault(
              record.description,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}
