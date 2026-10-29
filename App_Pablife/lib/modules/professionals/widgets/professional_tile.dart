import 'package:flutter/material.dart';
import '../../../infra/models/professional_with_user_model.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';

class ProfessionalTile extends StatelessWidget {
  final ProfessionalWithUserModel professional;
  final VoidCallback onTap;
  final VoidCallback onCalendarTap;

  const ProfessionalTile({
    super.key,
    required this.professional,
    required this.onTap,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAppointment = professional.hasAppointment;
    final bgColor = hasAppointment
        ? const Color(0xFF9BB1F1)
        : const Color(0xFFAEBEEC);

    final subtitleColor = hasAppointment
        ? const Color(0xFF3065FF)
        : const Color(0xFF0C8DA1);

    final calendarBgColor = hasAppointment
        ? const Color(0xFF3065FF)
        : const Color(0xFFC1CDFF);

    final calendarIcon = hasAppointment
        ? Icons.calendar_today
        : Icons.calendar_month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            AppImage(
              imageUrl: professional.user.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(40),
              errorWidget: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00343C).withAlpha(51),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: const Color(0xFF00343C).withAlpha(128),
                ),
              ),
            ),
            const SizedBox(width: 17),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextDefault(
                    professional.typeFormatted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00343C),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  TextDefault(
                    professional.user.fullName,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF00343C),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  TextDefault(
                    hasAppointment
                        ? professional.appointmentFormatted!
                        : professional.user.email,
                    fontSize: hasAppointment ? 10 : 14,
                    fontWeight: hasAppointment
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: subtitleColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: onCalendarTap,
              child: Container(
                width: 49.24,
                height: 48.5,
                decoration: BoxDecoration(
                  color: calendarBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  calendarIcon,
                  color: hasAppointment
                      ? Colors.white
                      : const Color(0xFF00343C),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
