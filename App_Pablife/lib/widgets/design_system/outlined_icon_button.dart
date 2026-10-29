import 'package:flutter/material.dart';

class OutlinedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color borderColor;
  final Color iconColor;
  final double size;

  const OutlinedIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.borderColor = Colors.white,
    this.iconColor = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 65,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size),
        ),
      ),
    );
  }
}
