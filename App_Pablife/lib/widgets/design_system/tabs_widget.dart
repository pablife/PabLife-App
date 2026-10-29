import 'package:flutter/material.dart';
import 'text_default.dart';

class TabsWidget extends StatefulWidget {
  final List<String> tabs;
  final String selectedTab;
  final void Function(String) onTabSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final Color? indicatorBackgroundColor;
  final double? fontSize;
  final FontWeight? selectedFontWeight;
  final FontWeight? unselectedFontWeight;

  const TabsWidget({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.indicatorBackgroundColor,
    this.fontSize = 16,
    this.selectedFontWeight = FontWeight.w500,
    this.unselectedFontWeight = FontWeight.w400,
  });

  @override
  State<TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<TabsWidget> {
  late ScrollController _scrollController;
  late ScrollController _indicatorScrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _indicatorScrollController = ScrollController();

    _scrollController.addListener(_syncIndicatorScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncIndicatorScroll);
    _scrollController.dispose();
    _indicatorScrollController.dispose();
    super.dispose();
  }

  void _syncIndicatorScroll() {
    if (!_isScrolling && _indicatorScrollController.hasClients) {
      _isScrolling = true;
      _indicatorScrollController.jumpTo(_scrollController.offset);
      Future.microtask(() => _isScrolling = false);
    }
  }

  double _getTabWidth(String tab, BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: tab,
        style: TextStyle(fontSize: widget.fontSize, fontFamily: 'Roboto Flex'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width + 16; // 16px de padding extra
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ?? const Color(0xFF00343C);
    final unselectedColor =
        widget.unselectedColor ?? const Color(0xFF00343C).withAlpha(128);
    final indicatorColor = widget.indicatorColor ?? const Color(0xFF00343C);
    final indicatorBgColor =
        widget.indicatorBackgroundColor ??
        const Color(0xFF00343C).withAlpha(51);

    return Column(
      children: [
        SizedBox(
          height: 30,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              final tab = widget.tabs[index];
              final isSelected = widget.selectedTab == tab;
              final width = _getTabWidth(tab, context);

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.tabs.length - 1 ? 16 : 0,
                ),
                child: SizedBox(
                  width: width,
                  child: GestureDetector(
                    onTap: () => widget.onTabSelected(tab),
                    child: TextDefault(
                      tab,
                      fontSize: widget.fontSize,
                      fontWeight: isSelected
                          ? widget.selectedFontWeight
                          : widget.unselectedFontWeight,
                      color: isSelected ? selectedColor : unselectedColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: indicatorBgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          height: 5,
          child: ListView.builder(
            controller: _indicatorScrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              final tab = widget.tabs[index];
              final isSelected = widget.selectedTab == tab;
              final width = _getTabWidth(tab, context);

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.tabs.length - 1
                      ? 16
                      : index == widget.tabs.length - 1
                      ? 32
                      : 0,
                ),
                child: Container(
                  width: width,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected ? indicatorColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
