import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import '../../../infra/models/professional_with_user_model.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';

class ProfessionalTile extends StatelessWidget {
  final ProfessionalWithUserModel professional;
  final VoidCallback onTap;
  final VoidCallback onCalendarTap;

  /// Destaca o card do profissional aberto no painel ao lado (computador).
  final bool isSelected;

  const ProfessionalTile({
    super.key,
    required this.professional,
    required this.onTap,
    required this.onCalendarTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAppointment = professional.hasAppointment;
    final bgColor = hasAppointment
        ? const AppColor(0xFF9BB1F1)
        : const AppColor(0xFFAEBEEC);

    final subtitleColor = hasAppointment
        ? const AppColor(0xFF3065FF)
        : const AppColor(0xFF0C8DA1);

    final calendarBgColor = hasAppointment
        ? const AppColor(0xFF3065FF)
        : const AppColor(0xFFC1CDFF);

    final calendarIcon = hasAppointment
        ? Icons.calendar_today
        : Icons.calendar_month;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(25),
          ),
          // Borda por cima (não ocupa espaço): o card tem altura fixa.
          foregroundDecoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const AppColor(0xFF00343C), width: 3),
                )
              : null,
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
                    color: const AppColor(0xFF00343C).withAlpha(51),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: const AppColor(0xFF00343C).withAlpha(128),
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
                      color: const AppColor(0xFF00343C),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    TextDefault(
                      professional.user.fullName,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: const AppColor(0xFF00343C),
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
                        : const AppColor(0xFF00343C),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
