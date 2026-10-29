import 'package:flutter/material.dart';
import '../../../infra/models/appointment_model.dart';
import '../../../infra/models/professional_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class AppointmentCardItem extends StatelessWidget {
  final AppointmentModel appointment;
  final ProfessionalModel? professional;
  final UserModel? user;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const AppointmentCardItem({
    super.key,
    required this.appointment,
    required this.professional,
    required this.user,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextDefault(
                          text: user?.fullName ?? 'Cliente',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        TextDefault(
                          text: user?.email ?? '-',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.person_outline,
                'Profissional',
                professional?.type ??
                    appointment.professionalId.substring(0, 6),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Data/Hora',
                formatDate(appointment.startOfScheduledWindow),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.info_outline,
                'Status',
                appointment.displayStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: TextDefault(
            text: '$label: $value',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
