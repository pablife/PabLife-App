import 'package:flutter/material.dart';
import 'package:pablife/widgets/design_system/whatsapp_icon.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../widgets/design_system/text_default.dart';
import 'reschedule_bottom_sheet_avatar_widget.dart';
import 'reschedule_time_picker_page.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;

  const RescheduleBottomSheet({super.key, required this.appointment});

  static Future<T?> show<T>(
    BuildContext context,
    ProfessionalAppointmentModel appointment,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleBottomSheet(appointment: appointment),
    );
  }

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  String? newAppointmentTimeId;

  Future<void> _onReschedulePressed() async {
    final result = await Get.to<String>(
      () => RescheduleTimePickerPage(
        professionalId: widget.appointment.professionalId,
      ),
    );

    if (result != null) {
      setState(() {
        newAppointmentTimeId = result;
      });
    }
  }

  void _onConfirmPressed() {
    if (newAppointmentTimeId != null) {
      Navigator.of(context).pop('confirmed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final startAt = widget.appointment.startAt;
    final dayNumber = DateFormat('dd').format(startAt);
    final monthLabel = DateFormat('MMM', 'pt_BR').format(startAt).toUpperCase();
    final weekdayLabel = _capitalizeString(
      DateFormat('EEEE', 'pt_BR').format(startAt),
    );
    final timeLabel = DateFormat('HH:mm').format(startAt);
    final dateLabel = DateFormat('dd/MM/yyyy').format(startAt);

    if (newAppointmentTimeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onConfirmPressed();
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFAEBEEC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFAEBEEC),
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                children: [
                  RescheduleBottomSheetAvatarWidget(
                    patientImageUrl: widget.appointment.patientImageUrl,
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const TextDefault(
                          'Paciente',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00343C),
                          height: 1.214,
                        ),
                        TextDefault(
                          widget.appointment.patientName,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF00343C),
                          height: 1.208,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        TextDefault(
                          dateLabel,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0C8DA1),
                          height: 1.214,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                          TextSpan(text: '$dayNumber.'),
                          TextSpan(
                            text: DateFormat('MM').format(startAt),
                            style: const TextStyle(fontSize: 48),
                          ),
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: monthLabel,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      weekdayLabel,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC1CDFF),
                      height: 1.222,
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Container(
                  width: 3,
                  height: 118.5,
                  color: const Color(0xFFC1CDFF),
                ),
                const SizedBox(width: 30),
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
                        timeLabel,
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
                        onTap: () => Navigator.of(context).pop('message'),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 10),
                            WhatsAppIcon(size: 32),
                            SizedBox(width: 8),
                            TextDefault(
                              'Enviar Mensagem',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.214,
                            ),
                          ],
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
                        onTap: _onReschedulePressed,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: TextDefault(
                                'Remarcar Consulta',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.214,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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

  String _capitalizeString(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
