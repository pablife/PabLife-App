import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class ProfessionalCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> professionals;
  final int currentIndex;
  final Function(int) onPageChanged;

  const ProfessionalCarousel({
    super.key,
    required this.professionals,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        onPageChanged: onPageChanged,
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final professional = professionals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff95B0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              professional['image'] ??
                                  'https://via.placeholder.com/80',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextDefault(
                              professional['role'] ?? '',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.aquaText,
                            ),
                            const SizedBox(height: 4),
                            TextDefault(
                              professional['name'] ?? '',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.aquaText,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xff3065FF),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: TextDefault(
                                professional['availableTime'] ?? '',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xff3065FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      professionals.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == currentIndex
                              ? Color(0xff3065FF)
                              : Color(0xffD9D9D9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
