import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/professional_with_user_model.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../appointment_details/widgets/reschedule_time_picker_page.dart';
import '../../calendar/widgets/interactive_calendar_base.dart';

class ScheduleAppointmentBottomSheet extends StatefulWidget {
  final ProfessionalWithUserModel professional;

  const ScheduleAppointmentBottomSheet({super.key, required this.professional});

  static Future<T?> show<T>(
    BuildContext context,
    ProfessionalWithUserModel professional,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ScheduleAppointmentBottomSheet(professional: professional),
    );
  }

  @override
  State<ScheduleAppointmentBottomSheet> createState() =>
      _ScheduleAppointmentBottomSheetState();
}

class _ScheduleAppointmentBottomSheetState
    extends State<ScheduleAppointmentBottomSheet> {
  String? selectedAppointmentTimeId;
  DateTime? selectedDate;

  Future<void> _onSchedulePressed() async {
    final result = await Get.to<CalendarSlotData>(
      () => RescheduleTimePickerPage(
        professionalId: widget.professional.professional.id!,
      ),
    );

    if (result != null && mounted) {
      // Return the selected slot immediately
      Navigator.of(context).pop(result);
    }
  }

  void _onConfirmPressed() {
    if (selectedAppointmentTimeId != null) {
      Navigator.of(context).pop(selectedAppointmentTimeId);
    }
  }

  void _onCancelPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDate != null) {
      return ScheduleAppointmentConfirmationWidget(
        professional: widget.professional,
        selectedDate: selectedDate!,
        onConfirm: _onConfirmPressed,
        onCancel: _onCancelPressed,
      );
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
                  ScheduleAppointmentAvatarWidget(
                    professional: widget.professional,
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextDefault(
                          widget.professional.typeFormatted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00343C),
                          height: 1.214,
                        ),
                        TextDefault(
                          widget.professional.user.fullName,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF00343C),
                          height: 1.208,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        TextDefault(
                          widget.professional.user.email,
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
          if (widget.professional.professional.description != null &&
              widget.professional.professional.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
              child: TextDefault(
                widget.professional.professional.description!,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF00343C),
                height: 1.5,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                            FaIcon(
                              FontAwesomeIcons.whatsapp,
                              color: Colors.white,
                              size: 32,
                            ),
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
                        onTap: _onSchedulePressed,
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
                                'Agendar Consulta',
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
}

class ScheduleAppointmentConfirmationWidget extends StatelessWidget {
  final ProfessionalWithUserModel professional;
  final DateTime selectedDate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ScheduleAppointmentConfirmationWidget({
    super.key,
    required this.professional,
    required this.selectedDate,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final newDayNumber = DateFormat('dd').format(selectedDate);
    final newMonthLabel = DateFormat(
      'MMM',
      'pt_BR',
    ).format(selectedDate).toUpperCase();
    final newWeekdayLabel = _capitalize(
      DateFormat('EEEE', 'pt_BR').format(selectedDate),
    );
    final newTimeLabel = DateFormat('HH:mm').format(selectedDate);

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
                  'Confirmar Agendamento',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00343C),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextDefault(
                  'Confirme o agendamento com ${professional.user.fullName}',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF00343C),
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
                            text: DateFormat('MM').format(selectedDate),
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

class ScheduleAppointmentAvatarWidget extends StatelessWidget {
  final ProfessionalWithUserModel professional;

  const ScheduleAppointmentAvatarWidget({
    super.key,
    required this.professional,
  });

  @override
  Widget build(BuildContext context) {
    if (professional.user.imageUrl != null &&
        professional.user.imageUrl!.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(professional.user.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00343C).withAlpha(51),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: const Color(0xFF00343C).withAlpha(128),
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
