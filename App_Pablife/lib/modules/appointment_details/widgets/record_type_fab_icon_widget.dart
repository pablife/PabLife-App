import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../infra/models/patient_record_model.dart';

class RecordTypeFabIconWidget extends StatelessWidget {
  final PatientRecordType type;

  const RecordTypeFabIconWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PatientRecordType.mealPlan:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/icons/food.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
          ),
        );
      case PatientRecordType.prescription:
        return const Icon(Symbols.prescriptions, color: Colors.white, size: 24);
      case PatientRecordType.observation:
        return const Icon(Symbols.note_alt, color: Colors.white, size: 24);
      case PatientRecordType.note:
        return const Icon(Symbols.note_stack, color: Colors.white, size: 24);
      case PatientRecordType.reflection:
        return const Icon(Symbols.neurology, color: Colors.white, size: 24);
      case PatientRecordType.practice:
        return const Icon(
          Symbols.assignment_ind,
          color: Colors.white,
          size: 24,
        );
    }
  }
}
