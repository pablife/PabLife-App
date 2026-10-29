import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../infra/models/professional_appointment_model.dart';

class CalendarExpandedCardWidget extends StatelessWidget {
  final DateTime date;
  final String dayNumber;
  final String monthLabel;
  final String weekdayLabel;
  final int tasksCount;
  final int notesCount;
  final List<ProfessionalAppointmentModel> appointments;
  final bool isProfessional;
  final VoidCallback? onViewDetails;

  const CalendarExpandedCardWidget({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.monthLabel,
    required this.weekdayLabel,
    required this.tasksCount,
    required this.notesCount,
    this.appointments = const [],
    this.isProfessional = false,
    this.onViewDetails,
  });

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      text: DateFormat('MM').format(date),
                      style: const TextStyle(fontSize: 48),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(text: monthLabel),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextDefault(
                _capitalize(weekdayLabel),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC1CDFF),
              ),
            ],
          ),
          const Spacer(),
          Container(width: 3, height: 118.5, color: const Color(0xFFC1CDFF)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isProfessional) ...[
                  if (appointments.isEmpty)
                    const TextDefault(
                      'Sem Consultas',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC1CDFF),
                    )
                  else ...[
                    const TextDefault(
                      'Consultas',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC1CDFF),
                    ),
                    const SizedBox(height: 10),
                    ...appointments.map((appointment) {
                      final time = DateFormat(
                        'HH:mm',
                      ).format(appointment.startAt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            TextDefault(
                              time,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFC1CDFF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextDefault(
                                appointment.patientName,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ] else ...[
                  if (tasksCount > 0) ...[
                    const TextDefault(
                      'Tarefas Agendadas',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC1CDFF),
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      '$tasksCount tarefa${tasksCount > 1 ? 's' : ''}',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFC1CDFF),
                    ),
                  ],
                  if (tasksCount > 0 && notesCount > 0)
                    const SizedBox(height: 12),
                  if (notesCount > 0) ...[
                    const TextDefault(
                      'Anotações',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC1CDFF),
                    ),
                    const SizedBox(height: 4),
                    TextDefault(
                      '$notesCount anotaç${notesCount > 1 ? 'ões' : 'ão'}',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFC1CDFF),
                    ),
                  ],
                  if (tasksCount == 0 && notesCount == 0) ...[
                    const TextDefault(
                      'Sem Eventos',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC1CDFF),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
