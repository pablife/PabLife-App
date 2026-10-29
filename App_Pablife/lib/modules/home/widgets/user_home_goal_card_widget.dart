import 'package:flutter/material.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../shared/themes/app_colors.dart';

import 'package:carousel_slider/carousel_slider.dart';
import '../../../infra/models/home_view_models.dart';

class UserHomeGoalCardWidget extends StatefulWidget {
  final List<GoalViewModel> goalCards;

  const UserHomeGoalCardWidget({super.key, required this.goalCards});

  @override
  State<UserHomeGoalCardWidget> createState() => _UserHomeGoalCardWidgetState();
}

class _UserHomeGoalCardWidgetState extends State<UserHomeGoalCardWidget> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            autoPlay: false,
            padEnds: false,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
          items: widget.goalCards.map((goal) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.yellowCard,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextDefault(
                          goal.tag,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        TextDefault(
                          goal.duration,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextDefault(
                      goal.title,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    Expanded(child: const SizedBox(height: 8)),
                    TextDefault(
                      goal.description,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.goalCards.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.goalCards.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == entry.key
                      ? AppColors.aqua
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
