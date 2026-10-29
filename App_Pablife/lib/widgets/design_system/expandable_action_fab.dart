import 'package:flutter/material.dart';

class ExpandableFabAction {
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;
  final Duration animationDelay;

  const ExpandableFabAction({
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x33FFFFFF),
    this.animationDelay = Duration.zero,
  }) : assert(icon != null || iconWidget != null);
}

class ExpandableActionFab extends StatefulWidget {
  const ExpandableActionFab({
    super.key,
    required this.actions,
    this.backgroundColor = const Color(0xFF0C8DA1),
    this.collapsedIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.expandedWidth = 280,
    this.height = 60,
    this.onExpandedChange,
  });

  final List<ExpandableFabAction> actions;
  final Color backgroundColor;
  final IconData collapsedIcon;
  final IconData closeIcon;
  final double expandedWidth;
  final double height;
  final ValueChanged<bool>? onExpandedChange;

  @override
  State<ExpandableActionFab> createState() => _ExpandableActionFabState();
}

class _ExpandableActionFabState extends State<ExpandableActionFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChange?.call(_isExpanded);
  }

  void _collapse() {
    if (!_isExpanded) return;
    setState(() {
      _isExpanded = false;
    });
    widget.onExpandedChange?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? widget.expandedWidth : widget.height,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: _isExpanded
            ? ExpandableActionFabExpanded(
                actions: widget.actions,
                closeIcon: widget.closeIcon,
                onClose: _toggle,
                onActionTap: (action) {
                  _collapse();
                  action.onTap();
                },
              )
            : ExpandableActionFabCollapsed(
                collapsedIcon: widget.collapsedIcon,
                isExpanded: _isExpanded,
                onTap: _toggle,
              ),
      ),
    );
  }
}

class ExpandableActionFabCollapsed extends StatelessWidget {
  final IconData collapsedIcon;
  final bool isExpanded;
  final VoidCallback onTap;

  const ExpandableActionFabCollapsed({
    super.key,
    required this.collapsedIcon,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          turns: isExpanded ? 0.125 : 0,
          child: Icon(collapsedIcon, color: Colors.white, size: 37),
        ),
      ),
    );
  }
}

class ExpandableActionFabExpanded extends StatelessWidget {
  final List<ExpandableFabAction> actions;
  final IconData closeIcon;
  final VoidCallback onClose;
  final void Function(ExpandableFabAction) onActionTap;

  const ExpandableActionFabExpanded({
    super.key,
    required this.actions,
    required this.closeIcon,
    required this.onClose,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionWidgets = <Widget>[
      _AnimatedFabButton(
        icon: closeIcon,
        iconWidget: null,
        iconColor: Colors.white,
        backgroundColor: Colors.white.withAlpha(51),
        delay: const Duration(milliseconds: 0),
        onTap: onClose,
      ),
      ...actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        final delay = action.animationDelay.isNegative
            ? Duration.zero
            : action.animationDelay;
        final effectiveDelay = delay == Duration.zero
            ? Duration(milliseconds: 50 * (index + 1))
            : delay;

        return _AnimatedFabButton(
          icon: action.icon,
          iconWidget: action.iconWidget,
          iconColor: action.iconColor,
          backgroundColor: action.backgroundColor,
          delay: effectiveDelay,
          onTap: () => onActionTap(action),
        );
      }),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actionWidgets,
    );
  }
}

class _AnimatedFabButton extends StatefulWidget {
  const _AnimatedFabButton({
    required this.icon,
    required this.iconWidget,
    required this.onTap,
    required this.delay,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  final Duration delay;
  final Color iconColor;
  final Color backgroundColor;

  @override
  State<_AnimatedFabButton> createState() => _AnimatedFabButtonState();
}

class _AnimatedFabButtonState extends State<_AnimatedFabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
            ),
            child:
                widget.iconWidget ??
                Icon(widget.icon, color: widget.iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}
