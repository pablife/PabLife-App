import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../infra/repositories/appointment_repository.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/design_system/text_default.dart';

class CreateScheduleSlotBottomSheet extends StatefulWidget {
  final String professionalId;

  const CreateScheduleSlotBottomSheet({
    super.key,
    required this.professionalId,
  });

  static Future<T?> show<T>(BuildContext context, String professionalId) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CreateScheduleSlotBottomSheet(professionalId: professionalId),
    );
  }

  @override
  State<CreateScheduleSlotBottomSheet> createState() =>
      _CreateScheduleSlotBottomSheetState();
}

class _CreateScheduleSlotBottomSheetState
    extends State<CreateScheduleSlotBottomSheet> {
  final appointmentRepository = AppointmentRepository();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool isRecurring = false;
  bool isLoading = false;
  Map<String, List<String>> availableSlotsByDate = {};
  Map<String, List<Map<String, DateTime>>> _slotIntervalsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  void _setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> _loadAvailableSlots() async {
    _setLoading(true);
    try {
      final response = await appointmentRepository.getProfessionalSlotsFromView(
        professionalId: widget.professionalId,
        date: selectedDate,
      );

      if (response.success && response.data != null) {
        final Map<String, List<Map<String, DateTime>>> grouped = {};
        for (final slot in response.data!) {
          final dateKey = DateFormat('yyyy-MM-dd').format(slot.startAt);

          if (!grouped.containsKey(dateKey)) {
            grouped[dateKey] = [];
          }
          grouped[dateKey]!.add({
            'start': slot.startAt,
            'finish': slot.finishAt,
          });
        }

        final Map<String, List<String>> timeSlotsByDate = {};
        for (final entry in grouped.entries) {
          timeSlotsByDate[entry.key] = entry.value.map((interval) {
            return '${DateFormat('HH:mm').format(interval['start']!)}-${DateFormat('HH:mm').format(interval['finish']!)}';
          }).toList();
        }

        setState(() {
          availableSlotsByDate = timeSlotsByDate;
          _slotIntervalsByDate = grouped;
        });
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _loadAvailableSlots();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0C8DA1)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  bool _isTimeAvailable(TimeOfDay time) {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final existingIntervals = _slotIntervalsByDate[dateKey] ?? [];

    final timeToCheck = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      time.hour,
      time.minute,
    );

    final isOccupied = existingIntervals.any((interval) {
      final start = interval['start']!;
      final finish = interval['finish']!;

      return timeToCheck.isAtSameMomentAs(start) ||
          (timeToCheck.isAfter(start) && timeToCheck.isBefore(finish));
    });

    return !isOccupied;
  }

  void _onConfirmPressed() {
    if (!_isTimeAvailable(selectedTime)) {
      AppSnackbar.to.show(
        'Este horário já foi criado. Por favor, selecione outro horário.',
      );
      return;
    }

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

    Navigator.of(
      context,
    ).pop({'dateTime': localDateTime, 'isRecurring': isRecurring});
  }

  void _onCancelPressed() {
    Navigator.of(context).pop('cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final selectedTimeStr =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final isTimeAvailable = _isTimeAvailable(selectedTime);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFAEBEEC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Column(
                children: [
                  const TextDefault(
                    'Criar Horário',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00343C),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const TextDefault(
                    'Selecione a data, horário e se deseja repetir',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF00343C),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0C8DA1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TextDefault(
                              'Data',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF00343C),
                            ),
                            const SizedBox(height: 4),
                            TextDefault(
                              DateFormat(
                                'dd/MM/yyyy',
                                'pt_BR',
                              ).format(selectedDate),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00343C),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF0C8DA1),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF0C8DA1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TextDefault(
                              'Horário',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF00343C),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                TextDefault(
                                  selectedTimeStr,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isTimeAvailable
                                      ? const Color(0xFF00343C)
                                      : Colors.red,
                                ),
                                if (!isTimeAvailable) ...[
                                  const SizedBox(width: 8),
                                  const TextDefault(
                                    '(já existe)',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF0C8DA1),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Checkbox(
                    value: isRecurring,
                    onChanged: (value) {
                      setState(() {
                        isRecurring = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF0C8DA1),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF0C8DA1);
                      }
                      return Colors.white;
                    }),
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: const Color(0xFF00343C).withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isRecurring = !isRecurring;
                        });
                      },
                      child: const TextDefault(
                        'Repetir este horário',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF00343C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
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
                          onTap: _onCancelPressed,
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
                      decoration: BoxDecoration(
                        color: isTimeAvailable
                            ? const Color(0xFF0C8DA1)
                            : Colors.grey,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isTimeAvailable ? _onConfirmPressed : null,
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
      ),
    );
  }
}
