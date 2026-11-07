import 'package:flutter/material.dart';

import '../../../infra/models/professional_with_user_model.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_image.dart';

/// Cartão do profissional na lista (canvas "Profissionais — mobile").
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

  String get _initials => professional.user.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.length > 2)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final hasAppointment = professional.hasAppointment;

    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? PabColors.ink : PabColors.line,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipOval(
                child: AppImage(
                  imageUrl: professional.user.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 52,
                    height: 52,
                    color: PabColors.lilac,
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PabColors.lilacText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      professional.typeFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PabColors.muted,
                      ),
                    ),
                    if (hasAppointment) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: PabColors.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Consulta ${professional.appointmentFormatted}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PabColors.accentText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: hasAppointment ? 'Ver consulta' : 'Agendar consulta',
                child: Material(
                  color: hasAppointment ? PabColors.accent : PabColors.soft,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onCalendarTap,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        hasAppointment
                            ? Icons.event_available
                            : Icons.calendar_month_outlined,
                        size: 22,
                        color: hasAppointment
                            ? PabColors.ink
                            : PabColors.accentText,
                      ),
                    ),
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
