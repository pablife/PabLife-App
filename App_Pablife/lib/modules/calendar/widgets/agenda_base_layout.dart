import 'package:flutter/material.dart';

import '../../../widgets/design_system/text_default.dart';

class AgendaHeaderInfo {
  final String primaryTitle;
  final String primarySubtitle;
  final String secondaryTitle;
  final String secondarySubtitle;

  const AgendaHeaderInfo({
    required this.primaryTitle,
    required this.primarySubtitle,
    required this.secondaryTitle,
    required this.secondarySubtitle,
  });
}

class AgendaFilterOption {
  final String id;
  final String label;
  final IconData? icon;

  const AgendaFilterOption({required this.id, required this.label, this.icon});
}

class AgendaCardData {
  final String id;
  final String title;
  final String timeLabel;
  final Color backgroundColor;
  final IconData? icon;
  final Color iconColor;
  final Color titleColor;
  final Color timeColor;
  final bool strikeThrough;
  final bool showToggle;
  final bool isCompleted;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isPlaceholder;
  final String? statusLabel;
  final Color? statusBackgroundColor;
  final Color statusTextColor;
  final double height;

  const AgendaCardData({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.backgroundColor,
    this.icon,
    this.iconColor = Colors.white,
    this.titleColor = Colors.white,
    this.timeColor = Colors.white,
    this.strikeThrough = false,
    this.showToggle = false,
    this.isCompleted = false,
    this.onToggle,
    this.onTap,
    this.trailing,
    this.isPlaceholder = false,
    this.statusLabel,
    this.statusBackgroundColor,
    this.statusTextColor = Colors.white,
    this.height = 54,
  });

  AgendaCardData copyWith({
    String? id,
    String? title,
    String? timeLabel,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    Color? titleColor,
    Color? timeColor,
    bool? strikeThrough,
    bool? showToggle,
    bool? isCompleted,
    VoidCallback? onToggle,
    VoidCallback? onTap,
    Widget? trailing,
    bool? isPlaceholder,
    String? statusLabel,
    Color? statusBackgroundColor,
    Color? statusTextColor,
    double? height,
  }) {
    return AgendaCardData(
      id: id ?? this.id,
      title: title ?? this.title,
      timeLabel: timeLabel ?? this.timeLabel,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      timeColor: timeColor ?? this.timeColor,
      strikeThrough: strikeThrough ?? this.strikeThrough,
      showToggle: showToggle ?? this.showToggle,
      isCompleted: isCompleted ?? this.isCompleted,
      onToggle: onToggle ?? this.onToggle,
      onTap: onTap ?? this.onTap,
      trailing: trailing ?? this.trailing,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      statusLabel: statusLabel ?? this.statusLabel,
      statusBackgroundColor:
          statusBackgroundColor ?? this.statusBackgroundColor,
      statusTextColor: statusTextColor ?? this.statusTextColor,
      height: height ?? this.height,
    );
  }
}

class AgendaHourBlock {
  final int hour;
  final List<AgendaCardData> items;
  final bool isHighlighted;
  final Color? highlightColor;

  const AgendaHourBlock({
    required this.hour,
    this.items = const [],
    this.isHighlighted = false,
    this.highlightColor,
  });
}

class AgendaBaseLayout extends StatefulWidget {
  const AgendaBaseLayout({
    super.key,
    required this.selectedDateTime,
    required this.dateLabel,
    required this.monthLabel,
    required this.weekdayLabel,
    required this.headerInfo,
    this.onHeaderTap,
    required this.filters,
    required this.selectedFilterId,
    required this.onFilterSelected,
    required this.hourBlocks,
    this.highlightedHour,
    this.scrollTargetHour,
    this.onScrollTargetConsumed,
    this.scrollToCurrentHour = false,
    this.scrollTrigger = 0,
    this.isLoading = false,
    this.floatingButton,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final DateTime selectedDateTime;
  final String dateLabel;
  final String monthLabel;
  final String weekdayLabel;
  final AgendaHeaderInfo headerInfo;
  final VoidCallback? onHeaderTap;
  final List<AgendaFilterOption> filters;
  final String selectedFilterId;
  final ValueChanged<String> onFilterSelected;
  final List<AgendaHourBlock> hourBlocks;
  final int? highlightedHour;
  final int? scrollTargetHour;
  final VoidCallback? onScrollTargetConsumed;
  final bool scrollToCurrentHour;
  final int scrollTrigger;
  final bool isLoading;
  final Widget? floatingButton;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  State<AgendaBaseLayout> createState() => _AgendaBaseLayoutState();
}

class _AgendaBaseLayoutState extends State<AgendaBaseLayout> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;
  int _lastScrollTrigger = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollTrigger != _lastScrollTrigger) {
      _lastScrollTrigger = widget.scrollTrigger;
      _hasScrolled = false;
    }
    if (widget.selectedDateTime != oldWidget.selectedDateTime) {
      _hasScrolled = false;
    }
    if (!widget.isLoading) {
      _scrollToHighlightedHour();
    }
  }

  void _scrollToHighlightedHour() {
    final targetHour =
        widget.scrollTargetHour ??
        (widget.scrollToCurrentHour
            ? DateTime.now().hour
            : widget.highlightedHour);
    final shouldNotifyScrollTarget = widget.scrollTargetHour != null;
    if (targetHour == null || _hasScrolled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || _hasScrolled) return;
      _scrollController.animateTo(
        targetHour * 64.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _hasScrolled = true;
      if (shouldNotifyScrollTarget) {
        widget.onScrollTargetConsumed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      _scrollToHighlightedHour();
    }

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF082C32),
      body: Stack(
        children: [
          Column(
            children: [
              if (widget.showBackButton) SizedBox(height: statusBarHeight),

              if (widget.showBackButton) _buildBackButton(),

              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
          if (widget.floatingButton != null)
            Positioned(right: 0, bottom: 85, child: widget.floatingButton!),
        ],
      ),
    );
  }

  Widget _buildBetaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3A42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C2A8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C2A8).withAlpha(38),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'Beta',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF00C2A8),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3A42),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFC1CDFF),
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          _buildBetaBadge(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final headerContent = Padding(
      padding: const EdgeInsets.fromLTRB(37, 0, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.dateLabel}\n${widget.monthLabel}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFC1CDFF),
                  height: 1.2,
                  fontFamily: 'Instrument Sans',
                ),
              ),
              const SizedBox(height: 8),
              TextDefault(
                widget.weekdayLabel,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC1CDFF),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            width: 3,
            height: 136,
            decoration: BoxDecoration(
              color: const Color(0xFFC1CDFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextDefault(
                  widget.headerInfo.primaryTitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC1CDFF),
                ),
                const SizedBox(height: 8),
                TextDefault(
                  widget.headerInfo.primarySubtitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFC1CDFF),
                ),
                const SizedBox(height: 16),
                TextDefault(
                  widget.headerInfo.secondaryTitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC1CDFF),
                ),
                const SizedBox(height: 8),
                TextDefault(
                  widget.headerInfo.secondarySubtitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFC1CDFF),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.onHeaderTap != null) {
      return GestureDetector(onTap: widget.onHeaderTap, child: headerContent);
    }

    return headerContent;
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFC1CDFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: widget.filters.map((filter) {
          final isSelected = filter.id == widget.selectedFilterId;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => widget.onFilterSelected(filter.id),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00343C)),
                    borderRadius: BorderRadius.circular(25),
                    color: isSelected
                        ? const Color(0xFF00343C).withAlpha(26)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextDefault(
                          filter.label,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF082C32),
                        ),
                        if (filter.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            filter.icon,
                            size: 18,
                            color: const Color(0xFF00343C),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: widget.hourBlocks.length,
      itemBuilder: (context, index) {
        final block = widget.hourBlocks[index];
        return _buildHourBlock(block);
      },
    );
  }

  double _calculateBlockHeight(List<AgendaCardData> items) {
    if (items.isEmpty) return 64;

    final double topPadding = 5;
    final double bottomPadding = 5;
    final double marginBetweenCards = 4;

    double totalHeight = topPadding;
    for (int i = 0; i < items.length; i++) {
      totalHeight += items[i].height;
      if (i < items.length - 1) {
        totalHeight += marginBetweenCards;
      }
    }
    totalHeight += bottomPadding;

    return totalHeight < 64 ? 64 : totalHeight;
  }

  Widget _buildHourBlock(AgendaHourBlock block) {
    final hasItems = block.items.isNotEmpty;
    final isHighlighted = block.isHighlighted && hasItems;
    final highlightColor = block.highlightColor ?? const Color(0xFF00C2A8);

    final double blockHeight = _calculateBlockHeight(block.items);

    return SizedBox(
      height: blockHeight,
      child: Stack(
        children: [
          if (isHighlighted) ...[
            Positioned(
              left: 0,
              top: 14,
              child: Container(
                width: 47,
                height: 37,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 30,
              child: Container(
                width: 65,
                height: 7,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
              ),
            ),
          ],
          if (hasItems)
            Positioned(
              left: 70,
              right: 16,
              top: 5,
              child: Column(
                children: block.items
                    .map((item) => _buildAgendaCard(item))
                    .toList(),
              ),
            ),
          Positioned(
            left: 12,
            top: 20,
            child: TextDefault(
              '${block.hour.toString().padLeft(2, '0')}h',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: isHighlighted ? Colors.white : const Color(0xFF00343C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(AgendaCardData data) {
    Widget cardContent = Container(
      height: data.height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (data.icon != null) ...[
              Icon(data.icon, color: data.iconColor, size: 28),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: data.titleColor,
                  decoration: data.strikeThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  fontFamily: 'Instrument Sans',
                ),
              ),
            ),
            if (data.statusLabel != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: data.statusBackgroundColor ?? Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextDefault(
                  data.statusLabel!,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.statusTextColor,
                ),
              ),
            ],
            const SizedBox(width: 12),
            TextDefault(
              data.timeLabel,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: data.timeColor,
            ),
            const SizedBox(width: 12),
            if (data.showToggle && data.onToggle != null)
              GestureDetector(
                onTap: data.onToggle,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: data.isCompleted
                        ? Colors.white.withAlpha(102)
                        : Colors.white.withAlpha(51),
                    border: Border.all(
                      color: Colors.white.withAlpha(153),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(39),
                  ),
                  child: data.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              )
            else if (data.trailing != null)
              data.trailing!,
          ],
        ),
      ),
    );

    if (data.onTap != null) {
      return GestureDetector(onTap: data.onTap, child: cardContent);
    }

    return cardContent;
  }
}
