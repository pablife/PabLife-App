import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarMonthSelectorWidget extends StatelessWidget {
  final DateTime currentMonth;
  final void Function(int) onChangeMonth;
  final bool compact;

  const CalendarMonthSelectorWidget({
    super.key,
    required this.currentMonth,
    required this.onChangeMonth,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);

    final currentMonthLabel = DateFormat(
      'MMM',
      'pt_BR',
    ).format(currentMonth).toUpperCase();
    final prevMonthLabel = DateFormat(
      'MMM',
      'pt_BR',
    ).format(prevMonth).toUpperCase();
    final nextMonthLabel = DateFormat(
      'MMM',
      'pt_BR',
    ).format(nextMonth).toUpperCase();

    if (compact) {
      return _buildCompactLayout(
        currentMonthLabel,
        prevMonthLabel,
        nextMonthLabel,
      );
    }

    return _buildFullLayout(currentMonthLabel, prevMonthLabel, nextMonthLabel);
  }

  Widget _buildCompactLayout(
    String currentMonthLabel,
    String prevMonthLabel,
    String nextMonthLabel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Previous month (smaller)
          GestureDetector(
            onTap: () => onChangeMonth(-1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
                Text(
                  prevMonthLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Current month (highlighted)
          Text(
            currentMonthLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(width: 16),

          // Next month (smaller)
          GestureDetector(
            onTap: () => onChangeMonth(1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nextMonthLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullLayout(
    String currentMonthLabel,
    String prevMonthLabel,
    String nextMonthLabel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Previous month label (faded)
          GestureDetector(
            onTap: () => onChangeMonth(-1),
            child: Text(
              prevMonthLabel,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Previous arrow
          GestureDetector(
            onTap: () => onChangeMonth(-1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left,
                color: Colors.white.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Current month (highlighted)
          Text(
            currentMonthLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(width: 12),

          // Next arrow
          GestureDetector(
            onTap: () => onChangeMonth(1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Next month label (faded)
          GestureDetector(
            onTap: () => onChangeMonth(1),
            child: Text(
              nextMonthLabel,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
