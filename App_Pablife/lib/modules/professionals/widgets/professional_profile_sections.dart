import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:pablife/widgets/design_system/app_image.dart';
import 'package:pablife/widgets/design_system/whatsapp_icon.dart';

import '../../../infra/models/professional_with_user_model.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/app_button_default.dart';

/// Partes do perfil do profissional usadas na página de detalhes (celular)
/// e no painel ao lado da lista (computador).

/// Foto redonda do profissional; clicar abre a foto ampliada.
class ProfessionalAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProfessionalAvatar({super.key, this.imageUrl, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: const AppColor(0xFF89BEC6),
      child: Icon(Icons.person, size: size / 2, color: Colors.white),
    );

    return GestureDetector(
      onTap: imageUrl != null
          ? () => showProfessionalPhoto(context, imageUrl!)
          : null,
      child: MouseRegion(
        cursor: imageUrl != null
            ? SystemMouseCursors.zoomIn
            : MouseCursor.defer,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.aquaText, width: 3),
          ),
          child: ClipOval(
            child: imageUrl != null
                ? AppImage(
                    imageUrl: imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorWidget: placeholder,
                  )
                : placeholder,
          ),
        ),
      ),
    );
  }
}

/// Selo com o tipo do profissional (Psicólogo, Nutricionista...).
class ProfessionalTypeChip extends StatelessWidget {
  final String label;

  const ProfessionalTypeChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.aquaText.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.aquaText,
        ),
      ),
    );
  }
}

/// Mostra a foto do profissional ampliada; dá para dar zoom e arrastar.
void showProfessionalPhoto(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppImage(imageUrl: imageUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: 'Fechar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Sobre, próxima consulta, contato e o botão de agendar/cancelar.
class ProfessionalProfileBody extends StatelessWidget {
  final ProfessionalWithUserModel professional;
  final VoidCallback onWhatsApp;
  final VoidCallback onScheduleAction;

  const ProfessionalProfileBody({
    super.key,
    required this.professional,
    required this.onWhatsApp,
    required this.onScheduleAction,
  });

  @override
  Widget build(BuildContext context) {
    final user = professional.user;
    final description = professional.professional.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null && description.isNotEmpty) ...[
          _buildSectionTitle('Sobre'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (professional.hasAppointment) ...[
          _buildSectionTitle('Sua Próxima Consulta'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const AppColor(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: AppColor(0xFF006064),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professional.appointmentFormatted ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor(0xFF00343C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Agendado',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor(0xFF006064),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        _buildSectionTitle('Contato'),
        const SizedBox(height: 12),
        _buildContactItem(icon: Icons.email_outlined, text: user.email),
        if (user.phone.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildContactItem(
            leading: const WhatsAppIcon(size: 20, color: AppColor(0xFF0C8DA1)),
            text: 'Conversar no WhatsApp',
            onTap: onWhatsApp,
            isAction: true,
          ),
        ],

        const SizedBox(height: 32),

        AppButtonDefault(
          text: professional.hasAppointment
              ? 'Cancelar Consulta'
              : 'Agendar Consulta',
          onTap: onScheduleAction,
          backgroundColor: professional.hasAppointment
              ? Colors.redAccent
              : const AppColor(0xFF0C8DA1),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColor(0xFF00343C),
      ),
    );
  }

  Widget _buildContactItem({
    IconData? icon,
    Widget? leading,
    required String text,
    VoidCallback? onTap,
    bool isAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: isAction ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isAction
                ? Border.all(color: const AppColor(0xFF0C8DA1), width: 1)
                : null,
          ),
          child: Row(
            children: [
              leading ??
                  Icon(
                    icon,
                    size: 20,
                    color: isAction
                        ? const AppColor(0xFF0C8DA1)
                        : Colors.grey[600],
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isAction
                        ? const AppColor(0xFF0C8DA1)
                        : Colors.black87,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isAction)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColor(0xFF0C8DA1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
