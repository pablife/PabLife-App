import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/next_slot_label.dart';
import '../professionals_controller.dart';
import '../widgets/professional_profile_sections.dart';
import 'professional_details_controller.dart';

/// Perfil do profissional no celular (canvas "Profissionais — mobile",
/// perfil aberto): topo escuro com foto e selos, Sobre, Contato e a barra
/// de baixo com o próximo horário e "Agendar".
class ProfessionalDetailsPage extends StatelessWidget {
  const ProfessionalDetailsPage({super.key});

  static const route = '/professional-details';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalDetailsController>(
      builder: (controller) {
        final professional = controller.professional;
        final user = professional.user;
        final list = Get.isRegistered<ProfessionalsController>()
            ? ProfessionalsController.to
            : null;
        final topics = list?.topicsOf(professional) ?? const <String>[];
        final next = list?.nextSlotOf(professional);

        Widget badge(String text, {bool strong = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: strong
                ? PabColors.accent
                : PabColors.onInk.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: strong ? PabColors.ink : PabColors.onInk,
            ),
          ),
        );

        return Scaffold(
          backgroundColor: PabColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: PabColors.ink,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Tooltip(
                            message: 'Voltar para a lista',
                            child: Material(
                              color: PabColors.onInk.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => Get.back<void>(),
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 20,
                                    color: PabColors.onInk,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              ProfessionalAvatar(
                                imageUrl: user.imageUrl,
                                size: 96,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Text(
                                  user.fullName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: PabColors.onInk,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  badge(
                                    professional.typeFormatted,
                                    strong: true,
                                  ),
                                  for (final topic in topics.take(2))
                                    badge(topic),
                                  badge('Online'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ProfessionalProfileBody(
                        professional: professional,
                        onWhatsApp: controller.openWhatsApp,
                        onScheduleAction: controller.handleScheduleAction,
                        showScheduleButton: false,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: PabColors.card,
                  border: Border(top: BorderSide(color: PabColors.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                professional.hasAppointment
                                    ? 'Sua consulta'
                                    : 'Próximo horário',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: PabColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                professional.hasAppointment
                                    ? professional.appointmentFormatted ?? ''
                                    : next != null
                                    ? nextSlotLabel(next)
                                    : 'Veja a agenda',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: PabColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ProfessionalScheduleButton(
                          hasAppointment: professional.hasAppointment,
                          onTap: controller.handleScheduleAction,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
