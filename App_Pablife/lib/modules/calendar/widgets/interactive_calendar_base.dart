import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modelo de dados para um evento no calendário
class CalendarEventData {
  final String id;
  final String label;
  final int count;
  final Color? color;

  /// Quando definido, será usado como label completo ao invés de "count label"
  final String? customLabel;

  const CalendarEventData({
    required this.id,
    required this.label,
    required this.count,
    this.color,
    this.customLabel,
  });

  /// Retorna o label formatado para exibição
  String get displayLabel => customLabel ?? '$count $label';
}

/// Modelo de dados para um slot de horário disponível
class CalendarSlotData {
  final String id;
  final DateTime startAt;
  final DateTime finishAt;
  final String? label;

  const CalendarSlotData({
    required this.id,
    required this.startAt,
    required this.finishAt,
    this.label,
  });

  String get timeLabel => DateFormat('HH:mm').format(startAt);
}

/// Modelo de dados para um dia no calendário
class CalendarDayData {
  final DateTime date;
  final List<CalendarEventData> events;
  final List<CalendarSlotData> slots;

  const CalendarDayData({
    required this.date,
    this.events = const [],
    this.slots = const [],
  });

  bool get hasEvents => events.any((e) => e.count > 0);
  bool get hasSlots => slots.isNotEmpty;
}

/// Modo de exibição do calendário
enum CalendarDisplayMode {
  /// Mostra eventos com contagem (tarefas, consultas, etc)
  events,

  /// Mostra slots de horários selecionáveis
  slots,
}

/// Widget base para o calendário interativo
class InteractiveCalendarBase extends StatefulWidget {
  const InteractiveCalendarBase({
    super.key,
    required this.days,
    this.onDayTap,
    this.onSlotTap,
    this.displayMode = CalendarDisplayMode.events,
    this.expandedDateKey,
    this.onExpandedChanged,
    this.showTopBorderRadius = true,
    this.scrollToToday = false,
    this.scrollTrigger = 0,
  });

  final List<CalendarDayData> days;
  final void Function(DateTime date)? onDayTap;
  final void Function(CalendarSlotData slot)? onSlotTap;
  final CalendarDisplayMode displayMode;
  final String? expandedDateKey;
  final void Function(String? dateKey)? onExpandedChanged;
  final bool showTopBorderRadius;
  final bool scrollToToday;
  final int scrollTrigger;

  @override
  State<InteractiveCalendarBase> createState() =>
      _InteractiveCalendarBaseState();
}

class _InteractiveCalendarBaseState extends State<InteractiveCalendarBase> {
  final ScrollController _scrollController = ScrollController();
  String? _expandedDateKey;
  bool _hasAutoScrolled = false;
  int _lastScrollTrigger = 0;

  @override
  void initState() {
    super.initState();
    _expandedDateKey = widget.expandedDateKey;
    _lastScrollTrigger = widget.scrollTrigger;
  }

  @override
  void didUpdateWidget(InteractiveCalendarBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandedDateKey != oldWidget.expandedDateKey) {
      _expandedDateKey = widget.expandedDateKey;
    }
    if (widget.scrollTrigger != _lastScrollTrigger) {
      _lastScrollTrigger = widget.scrollTrigger;
      _hasAutoScrolled = false;
    }
    _scrollToTodayIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTodayIfNeeded() {
    if (!widget.scrollToToday || _hasAutoScrolled) {
      return;
    }

    final now = DateTime.now();
    final todayIndex = widget.days.indexWhere(
      (day) =>
          day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day,
    );

    if (todayIndex < 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || _hasAutoScrolled) {
        return;
      }
      final targetOffset = (todayIndex * 170.0) - 120.0;
      _scrollController.animateTo(
        targetOffset < 0 ? 0 : targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _hasAutoScrolled = true;
    });
  }

  void _toggleExpanded(String dateKey) {
    setState(() {
      if (_expandedDateKey == dateKey) {
        _expandedDateKey = null;
      } else {
        _expandedDateKey = dateKey;
      }
    });
    widget.onExpandedChanged?.call(_expandedDateKey);
  }

  @override
  Widget build(BuildContext context) {
    _scrollToTodayIfNeeded();
    final borderRadius = widget.showTopBorderRadius
        ? const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          )
        : BorderRadius.zero;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: widget.days.length,
          itemBuilder: (context, index) {
            final dayData = widget.days[index];
            final dateKey = DateFormat('yyyy-MM-dd').format(dayData.date);
            final isExpanded =
                widget.displayMode == CalendarDisplayMode.slots &&
                dayData.hasSlots &&
                _expandedDateKey == dateKey;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DayCard(
                dayData: dayData,
                colorIndex: index,
                displayMode: widget.displayMode,
                isExpanded: isExpanded,
                onTap: widget.displayMode == CalendarDisplayMode.events
                    ? (widget.onDayTap != null
                          ? () => widget.onDayTap!(dayData.date)
                          : null)
                    : (dayData.hasSlots
                          ? () => _toggleExpanded(dateKey)
                          : null),
                onSlotTap: widget.onSlotTap,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.dayData,
    required this.colorIndex,
    this.onTap,
    this.displayMode = CalendarDisplayMode.events,
    this.isExpanded = false,
    this.onSlotTap,
  });

  final CalendarDayData dayData;
  final int colorIndex;
  final VoidCallback? onTap;
  final CalendarDisplayMode displayMode;
  final bool isExpanded;
  final void Function(CalendarSlotData slot)? onSlotTap;

  static const List<Color> _backgroundColors = [
    Color(0xFFD8D4E8), // Lavender/Purple light
    Color(0xFFE0C8D0), // Rose/Pink light
    Color(0xFFC8E0D8), // Mint/Teal light
    Color(0xFFE8E0C8), // Cream/Yellow light
    Color(0xFFD0D8E8), // Sky/Blue light
    Color(0xFFE8D8C8), // Peach light
  ];

  static const List<Color> _textColors = [
    Color(0xFF4A3F6B), // Purple dark
    Color(0xFF6B4A5A), // Rose dark
    Color(0xFF3A5A4A), // Teal dark
    Color(0xFF5A5030), // Olive dark
    Color(0xFF3A4A6B), // Blue dark
    Color(0xFF6B5A3A), // Brown dark
  ];

  // Cores de destaque para slots selecionáveis (matching text colors)
  static const List<Color> _slotButtonColors = [
    Color(0xFF4A3F6B), // Purple
    Color(0xFF6B4A5A), // Rose
    Color(0xFF3A5A4A), // Teal
    Color(0xFF5A5030), // Olive
    Color(0xFF3A4A6B), // Blue
    Color(0xFF6B5A3A), // Brown
  ];

  Color get _backgroundColor =>
      _backgroundColors[colorIndex % _backgroundColors.length];

  Color get _textColor => _textColors[colorIndex % _textColors.length];

  Color get _slotButtonColor =>
      _slotButtonColors[colorIndex % _slotButtonColors.length];

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEEE', 'pt_BR').format(dayData.date);
    final weekdayCapitalized = weekday[0].toUpperCase() + weekday.substring(1);
    final dayNumber = dayData.date.day.toString();
    final monthAbbr = DateFormat(
      'MMM',
      'pt_BR',
    ).format(dayData.date).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Date info
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekdayCapitalized,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textColor.withValues(alpha: 0.8),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        height: 0.9,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      monthAbbr,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        height: 0.9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: _textColor.withValues(alpha: 0.2),
              ),

              // Right side - Events or Slots
              Expanded(child: _buildRightSection()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSection() {
    if (displayMode == CalendarDisplayMode.slots) {
      return _buildSlotsSection();
    }
    return _buildEventsSection();
  }

  Widget _buildSlotsSection() {
    if (!dayData.hasSlots) {
      return Center(
        child: Text(
          'Sem horários disponíveis',
          style: TextStyle(
            fontSize: 14,
            color: _textColor.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (!isExpanded) {
      // Modo colapsado - mostra apenas o contador
      return Center(
        child: Text(
          '${dayData.slots.length} Horários Disponíveis',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      );
    }

    // Modo expandido - mostra os slots selecionáveis
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horários Disponíveis',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dayData.slots.map((slot) {
            return GestureDetector(
              onTap: onSlotTap != null ? () => onSlotTap!(slot) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _slotButtonColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slot.timeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    final eventsWithCount = dayData.events.where((e) => e.count > 0).toList();

    if (eventsWithCount.isEmpty) {
      return Center(
        child: Text(
          'Sem eventos',
          style: TextStyle(
            fontSize: 14,
            color: _textColor.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: eventsWithCount.map((event) {
            return _EventPill(
              label: event.displayLabel,
              color: event.color ?? _textColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
