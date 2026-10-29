import 'package:flutter/material.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:pablife/shared/themes/app_colors.dart';

import '../dashboard_controller.dart';

class DashboardNavbar extends StatelessWidget {
  final DashboardController controller;
  const DashboardNavbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.aqua,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          DashboardNavbarItem(
            icon: RegularRounded.HOME,
            isSelected: controller.currentIndex == 0,
            onTap: () => controller.changeTab(0),
          ),
          DashboardNavbarItem(
            icon: RegularRounded.CALENDAR,
            isSelected: controller.currentIndex == 1,
            onTap: () => controller.changeTab(1),
          ),
          DashboardNavbarItem(
            icon: RegularRounded.BOOK_ALT,
            isSelected: controller.currentIndex == 2,
            onTap: () => controller.changeTab(2),
          ),
          DashboardNavbarItem(
            icon: RegularRounded.BRIEFCASE,
            isSelected: controller.currentIndex == 3,
            onTap: () => controller.changeTab(3),
          ),
          DashboardNavbarItem(
            icon: RegularRounded.USER,
            isSelected: controller.currentIndex == 4,
            onTap: () => controller.changeTab(4),
          ),
        ],
      ),
    );
  }
}

class DashboardNavbarItem extends StatelessWidget {
  final String icon;
  final bool isSelected;
  final Function() onTap;
  const DashboardNavbarItem({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: TweenAnimationBuilder<Color?>(
        key: ValueKey(isSelected),
        tween: ColorTween(
          begin: const Color(0xFF374957),
          end: isSelected ? AppColors.white : const Color(0xFF374957),
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        builder: (context, color, child) {
          return FUI(icon, color: color ?? const Color(0xFF374957), height: 24);
        },
      ),
    );
  }
}
