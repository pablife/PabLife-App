import 'package:flutter/material.dart';
import 'package:pablife/widgets/design_system/app_image.dart';
import 'package:pablife/widgets/design_system/whatsapp_icon.dart';

import '../../../infra/models/professional_with_user_model.dart';
import '../../../shared/themes/pab_colors.dart';

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
      color: PabColors.lilac,
      child: Icon(Icons.person, size: size / 2, color: PabColors.lilacText),
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
            border: Border.all(
              color: PabColors.onInk.withValues(alpha: 0.2),
              width: 4,
            ),
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

  /// Selo mais claro, para os temas.
  final bool soft;

  const ProfessionalTypeChip(this.label, {super.key, this.soft = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: soft ? PabColors.lilac : PabColors.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: soft ? PabColors.lilacText : PabColors.softText,
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

/// Sobre, sua consulta (se houver), contato e, no computador, o botão de
/// agendar ou cancelar (canvas "Profissionais", perfil aberto).
class ProfessionalProfileBody extends StatelessWidget {
  final ProfessionalWithUserModel professional;
  final VoidCallback onWhatsApp;
  final VoidCallback onScheduleAction;

  /// No celular o "Agendar" fica na barra de baixo da página.
  final bool showScheduleButton;

  const ProfessionalProfileBody({
    super.key,
    required this.professional,
    required this.onWhatsApp,
    required this.onScheduleAction,
    this.showScheduleButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = professional.user;
    final description = professional.professional.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description.isNotEmpty) ...[
          const _SectionTitle('Sobre'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Color(0xFF2E4446),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (professional.hasAppointment) ...[
          const _SectionTitle('Sua consulta'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 22,
                  color: PabColors.softText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    professional.appointmentFormatted ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PabColors.softText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (user.phone.isNotEmpty) ...[
          const _SectionTitle('Contato'),
          const SizedBox(height: 8),
          Material(
            color: PabColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: PabColors.lineStrong),
            ),
            child: InkWell(
              onTap: onWhatsApp,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                height: 52,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      WhatsAppIcon(size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Conversar no WhatsApp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (showScheduleButton)
          ProfessionalScheduleButton(
            hasAppointment: professional.hasAppointment,
            onTap: onScheduleAction,
          ),
      ],
    );
  }
}

/// "Agendar" (ou "Cancelar consulta", quando já há uma marcada).
class ProfessionalScheduleButton extends StatelessWidget {
  final bool hasAppointment;
  final VoidCallback onTap;

  const ProfessionalScheduleButton({
    super.key,
    required this.hasAppointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hasAppointment) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: PabColors.card,
          foregroundColor: PabColors.error,
          side: const BorderSide(color: PabColors.errorLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Cancelar consulta',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: PabColors.accent,
        foregroundColor: PabColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Agendar',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: PabColors.ink,
      ),
    );
  }
}
