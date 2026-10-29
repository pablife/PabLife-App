import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/design_system/text_default.dart';

class RescheduleBottomSheetConfirmationWidget extends StatelessWidget {
  final DateTime newStartAt;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const RescheduleBottomSheetConfirmationWidget({
    super.key,
    required this.newStartAt,
    required this.onConfirm,
    required this.onCancel,
  });

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final newDayNumber = DateFormat('dd').format(newStartAt);
    final newMonthLabel = DateFormat(
      'MMM',
      'pt_BR',
    ).format(newStartAt).toUpperCase();
    final newWeekdayLabel = _capitalize(
      DateFormat('EEEE', 'pt_BR').format(newStartAt),
    );
    final newTimeLabel = DateFormat('HH:mm').format(newStartAt);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFC1CDFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const TextDefault(
                  'Confirmar Reagendamento',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00343C),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const TextDefault(
                  'Confirme o reagendamento para enviar o novo horário ao paciente',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF00343C),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            height: 214,
            width: double.infinity,
            color: const Color(0xFF3065FF),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: 48,
                          height: 1.229,
                          color: Color(0xFFC1CDFF),
                        ),
                        children: [
                          TextSpan(text: '$newDayNumber.'),
                          TextSpan(
                            text: DateFormat('MM').format(newStartAt),
                            style: const TextStyle(fontSize: 48),
                          ),
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: newMonthLabel,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      newWeekdayLabel,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC1CDFF),
                      height: 1.222,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 3,
                  height: 118.5,
                  color: const Color(0xFFC1CDFF),
                ),
                const Spacer(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TextDefault(
                        'Horário',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC1CDFF),
                        height: 1.222,
                      ),
                      const SizedBox(height: 8),
                      TextDefault(
                        newTimeLabel,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFC1CDFF),
                        height: 1.222,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00343C),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCancel,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: const Center(
                          child: TextDefault(
                            'Cancelar',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.214,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C8DA1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onConfirm,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        ),
                        child: const Center(
                          child: TextDefault(
                            'Confirmar',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.214,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
