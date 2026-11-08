import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/app_palette.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../dashboard/dashboard_page.dart';
import '../../profile/pages/subscription_page.dart';
import 'widgets/registration_layout.dart';

/// "Conta criada!" (canvas E5): topo escuro com a ilustração, o aviso do
/// comprovante (se foi enviado) e o próximo passo, escolher o plano.
class AccountCreatedPage extends StatelessWidget {
  const AccountCreatedPage({super.key});

  static const route = '/auth/account-created';

  static const _page = AppColor.pair(0xFFE9EEEE, 0xFFF6EEF3);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map ? Get.arguments as Map : const {};
    final proofSent = args['proofSent'] == true;
    final proofError = args['proofError'] as String?;
    final wide = isWideLayout(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Image.asset(
                    AppPalette.isRose
                        ? 'assets/pages/auth/login_art_rose.png'
                        : 'assets/pages/auth/login_art.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conta criada!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: PabColors.onInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bem-vindo(a) à Pablife. Agora é só escolher seu plano.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: PabColors.navIdle,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            children: [
              if (proofSent)
                const _InfoCard(
                  icon: Icons.schedule,
                  iconBg: Color(0xFFFFF1D6),
                  iconFg: Color(0xFF6B4A00),
                  title: 'Comprovante em análise',
                  text:
                      'Respondemos em até 24 horas. Quando aprovar, o '
                      'desconto de 10% aparece em todos os planos.',
                ),
              if (proofError != null)
                _InfoCard(
                  icon: Icons.error_outline,
                  iconBg: const Color(0xFFFDE7EB),
                  iconFg: PabColors.error,
                  title: 'O comprovante não foi enviado',
                  text: '$proofError Você pode enviar de novo pelo Perfil.',
                ),
              if (proofSent || proofError != null) const SizedBox(height: 12),
              const _InfoCard(
                title: 'Próximo passo: escolher seu plano',
                text: 'Lite, Plus ou Premium, com 1, 3 ou 5 consultas online.',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegPrimaryButton(
                  label: 'Ver planos',
                  onTap: () {
                    Get.offAllNamed(DashboardPage.route);
                    Get.toNamed(SubscriptionPage.route);
                  },
                ),
                const SizedBox(height: 4),
                RegTextButton(
                  label: 'Ir para o Dashboard',
                  onTap: () => Get.offAllNamed(DashboardPage.route),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!wide) {
      return Scaffold(backgroundColor: PabColors.background, body: content);
    }
    return Scaffold(
      backgroundColor: _page,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 820),
            child: Container(
              decoration: BoxDecoration(
                color: PabColors.background,
                border: Border.all(color: PabColors.line),
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconBg;
  final Color? iconFg;
  final String title;
  final String text;

  const _InfoCard({
    required this.title,
    required this.text,
    this.icon,
    this.iconBg,
    this.iconFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconFg),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: PabColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
