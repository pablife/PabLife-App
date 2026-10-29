import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/themes/app_colors.dart';
import 'text_default.dart';

enum EdgeSide { left, right }

class EdgeButtonRounded extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeSide side;
  final double? width;
  final BorderRadius? inverseRadius;
  final Widget? icon;
  final double iconSpacing;
  final bool showText;

  const EdgeButtonRounded({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.side = EdgeSide.right,
    this.width,
    this.inverseRadius,
    this.icon,
    this.iconSpacing = 8,
    this.showText = true,
  });

  @override
  State<EdgeButtonRounded> createState() => _EdgeButtonRoundedState();
}

class _EdgeButtonRoundedState extends State<EdgeButtonRounded> {
  bool _isLoading = false;
  void _changeLoadingState(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: widget.isLoading || _isLoading
            ? null
            : () async {
                _changeLoadingState(true);
                await widget.onTap?.call();
                _changeLoadingState(false);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? AppColors.aquaButton,
          foregroundColor: widget.textColor ?? AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: widget.side == EdgeSide.left
                  ? Radius.circular(100)
                  : widget.inverseRadius?.topLeft ?? Radius.zero,
              bottomLeft: widget.side == EdgeSide.left
                  ? Radius.circular(100)
                  : widget.inverseRadius?.bottomLeft ?? Radius.zero,
              topRight: widget.side == EdgeSide.right
                  ? Radius.circular(100)
                  : widget.inverseRadius?.topRight ?? Radius.zero,
              bottomRight: widget.side == EdgeSide.right
                  ? Radius.circular(100)
                  : widget.inverseRadius?.bottomRight ?? Radius.zero,
            ),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          disabledBackgroundColor:
              (widget.backgroundColor ?? const Color(0xFF2D5A5A)).withAlpha(
                150,
              ),
        ),
        child: widget.isLoading || _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.textColor ?? AppColors.white,
                  ),
                ),
              )
            : EdgeButtonRoundedContent(
                text: widget.text,
                icon: widget.icon,
                showText: widget.showText,
                iconSpacing: widget.iconSpacing,
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                textColor: widget.textColor,
              ),
      ),
    );
  }
}

class EdgeButtonRoundedContent extends StatelessWidget {
  final String text;
  final Widget? icon;
  final bool showText;
  final double iconSpacing;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;

  const EdgeButtonRoundedContent({
    super.key,
    required this.text,
    this.icon,
    required this.showText,
    required this.iconSpacing,
    this.fontSize,
    this.fontWeight,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = TextDefault(
      text,
      key: const ValueKey('text'),
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: textColor ?? AppColors.white,
    );

    if (icon == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: showText ? textWidget : const SizedBox.shrink(),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon!,
        if (showText) SizedBox(width: iconSpacing),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: showText
              ? textWidget
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}
