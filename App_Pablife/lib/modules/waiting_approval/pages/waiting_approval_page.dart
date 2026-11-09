import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../../onboarding/onboarding_page.dart';
import '../../../widgets/design_system/whatsapp_icon.dart';
import '../controllers/waiting_approval_controller.dart';

/// "Cadastro em análise" (canvas PC3, passo 3 de 3). Aparece logo depois do
/// envio e sempre que o profissional entra antes da aprovação.
class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  static const route = '/waiting-approval';

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    Get.offAllNamed(OnboardingPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WaitingApprovalController>(
      builder: (controller) {
        final steps = [
          ('✓', 'Dados e registro', 'Recebidos', PabColors.ink, Colors.white),
          (
            '2',
            'Conferência no conselho',
            'Em análise · resposta em até 24 horas',
            PabColors.accent,
            PabColors.ink,
          ),
          (
            '3',
            'Perfil liberado para pacientes',
            'Depois da aprovação',
            PabColors.line,
            PabColors.muted,
          ),
        ];

        return RegistrationLayout(
          title: 'Cadastro em análise',
          step: 'Cadastro do profissional · passo 3 de 3',
          progress: 3,
          maxWidth: 560,
          fields: [
            Column(
              children: [
                ExcludeSemantics(
                  child: Image.asset(
                    AppPalette.isRose
                        ? 'assets/pages/auth/login_art_rose.png'
                        : 'assets/pages/auth/login_art.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cadastro enviado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estamos conferindo seu registro no conselho. Você recebe '
                  'um aviso no e-mail e no app quando o perfil for aprovado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: PabColors.muted,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PabColors.card,
                border: Border.all(color: PabColors.line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (final (mark, title, sub, bg, fg) in steps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: mark == '✓'
                                ? Icon(Icons.check, size: 16, color: fg)
                                : Text(
                                    mark,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: fg,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PabColors.ink,
                                  ),
                                ),
                                Text(
                                  sub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PabColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: PabColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Assim que o perfil for aprovado, você monta sua semana de '
                'atendimentos e escreve seu perfil. Pacientes só veem você '
                'depois da aprovação.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: PabColors.softText,
                ),
              ),
            ),
          ],
          footer: [
            RegPrimaryButton(
              label: 'Falar com a equipe no WhatsApp',
              icon: const WhatsAppIcon(size: 20, color: PabColors.ink),
              onTap: controller.openWhatsApp,
            ),
            const SizedBox(height: 4),
            RegTextButton(label: 'Sair da conta', onTap: _signOut),
          ],
        );
      },
    );
  }
}
