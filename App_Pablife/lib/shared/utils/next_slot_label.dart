import 'package:intl/intl.dart';

/// "Hoje às 16:00", "Amanhã às 09:00" ou "Seg, 9/11 às 08:00".
String nextSlotLabel(DateTime start, {DateTime? now}) {
  final local = start.toLocal();
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = DateFormat('HH:mm').format(local);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Hoje às $time';
  if (diff == 1) return 'Amanhã às $time';
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return '${weekdays[local.weekday - 1]}, ${local.day}/${local.month} às $time';
}
