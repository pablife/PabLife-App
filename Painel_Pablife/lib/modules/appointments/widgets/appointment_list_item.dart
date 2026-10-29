import 'package:flutter/material.dart';
import '../../../infra/models/appointment_model.dart';
import '../../../infra/models/professional_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';

class AppointmentListItem extends StatelessWidget {
  final AppointmentModel appointment;
  final ProfessionalModel? professional;
  final UserModel? user;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const AppointmentListItem({
    super.key,
    required this.appointment,
    required this.professional,
    required this.user,
    required this.formatDate,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (appointment.displayStatus) {
      case 'Concluído':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      case 'Agendado':
        return Colors.blue;
      case 'Em andamento':
        return Colors.orange;
      case 'Atrasado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.primaryGreen,
            size: 30,
          ),
        ),
        title: TextDefault(
          text: user?.fullName ?? 'Cliente',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TextDefault(
              text: formatDate(appointment.startOfScheduledWindow),
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextDefault(
                    text:
                        '${professional?.name != null ? '${professional?.name} - ' : ''}'
                        '${professional?.translatedType ?? appointment.professionalId.substring(0, 6)}',

                    fontSize: 12,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextDefault(
                    text: appointment.displayStatus,
                    fontSize: 12,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
