import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/app_palette.dart';
import '../../dashboard/dashboard_page.dart';
import '../../onboarding/onboarding_page.dart';
import '../../onboarding/widgets/onboarding_background.dart';
import '../../waiting_approval/pages/waiting_approval_page.dart';
import 'email_input_page.dart';
import 'professional_profile_page.dart';
import 'widgets/auth_animated_background.dart';

const _scene = OnboardingScene(
  gradient: [
    AppColor.pair(0xFFDFE5FD, 0xFFF7F1EF),
    AppColor.pair(0xFFD5DFFC, 0xFFF1E7EE),
    AppColor.pair(0xFFCCCBF8, 0xFFE3D8F8),
  ],
  blobs: [
    BackgroundBlob(
      right: -80,
      bottom: -90,
      width: 300,
      height: 250,
      color: OnboardingColors.yellow,
      opacity: .85,
    ),
    BackgroundBlob(
      right: 140,
      bottom: -110,
      width: 220,
      height: 200,
      color: OnboardingColors.sky,
      opacity: .8,
      delay: 6,
      period: 17,
    ),
    BackgroundBlob(
      left: -90,
      bottom: -100,
      width: 260,
      height: 220,
      color: OnboardingColors.lilac,
      opacity: .8,
      delay: 4,
    ),
    BackgroundBlob(
      left: .08,
      top: .12,
      width: 54,
      height: 54,
      color: OnboardingColors.sky,
      opacity: .8,
      delay: 2,
      period: 10,
    ),
    BackgroundBlob(
      right: .12,
      top: .22,
      width: 72,
      height: 68,
      color: OnboardingColors.lilac,
      opacity: .75,
      delay: 7,
      period: 12,
    ),
  ],
  bubbles: [
    BackgroundBubble(.3, 30, 12, OnboardingColors.lilac),
    BackgroundBubble(.58, 10, 16, OnboardingColors.sky, delay: 4),
    BackgroundBubble(.82, 50, 10, OnboardingColors.lilac, delay: 7),
  ],
  waveTop: .66,
  cloudLeft: .22,
  cloudTop: .08,
  cloudWidth: 140,
);

/// "Você é?": última tela antes do e-mail. Quem tem conta de profissional
/// também passa por aqui para trocar de lado, pelo Perfil. É a mesma conta
/// (mesmo e-mail, CPF e senha) nos dois lados.
class ChooseProfilePage extends StatefulWidget {
  const ChooseProfilePage({super.key});

  static const route = '/choose-profile';

  /// Leva para o lado escolhido depois do login ou do cadastro.
  static Future<void> enterAfterLogin() async {
    final auth = AuthService.instance;
    final choice = auth.entryChoice;
    auth.entryChoice = null;

    if (!auth.isProfessionalAccount) {
      if (choice == 'professional') {
        // Conta de usuário: completa o cadastro de profissional.
        Get.offAllNamed(
          ProfessionalProfilePage.route,
          arguments: {'addToExisting': true},
        );
        return;
      }
      Get.offAllNamed(DashboardPage.route);
    } else if (choice == 'user') {
      await _enterUserSide();
    } else if (choice == 'professional') {
      await _enterProfessionalSide();
    } else {
      Get.offAllNamed(route);
    }
  }

  static Future<void> _enterUserSide() async {
    await AuthService.instance.setActingAsUser(true);
    Get.offAllNamed(DashboardPage.route);
  }

  static Future<void> _enterProfessionalSide() async {
    final auth = AuthService.instance;
    await auth.setActingAsUser(false);

    final response = await ProfessionalRepository().getProfessionalByUserId(
      auth.currentUser!.id!,
    );
    final status = response.data?.validationStatus;
    if (response.success && status != null && status != 'approved') {
      Get.offAllNamed(WaitingApprovalPage.route);
      return;
    }
    Get.offAllNamed(DashboardPage.route);
  }

  @override
  State<ChooseProfilePage> createState() => _ChooseProfilePageState();
}

class _ChooseProfilePageState extends State<ChooseProfilePage> {
  bool _loading = false;
  String? _choice;

  bool get _beforeLogin => !AuthService.instance.isAuthenticated;

  /// Conta logada sem lado escolhido não tem para onde voltar.
  bool get _canGoBack => _beforeLogin || AuthService.instance.hasChosenProfile;

  void _back() => Get.offAllNamed(
    _beforeLogin ? OnboardingPage.route : DashboardPage.route,
  );

  Future<void> _continue() async {
    final choice = _choice;
    if (choice == null) return;

    if (_beforeLogin) {
      AuthService.instance.entryChoice = choice;
      Get.offAllNamed(EmailInputPage.route);
      return;
    }
    setState(() => _loading = true);
    if (choice == 'user') {
      await ChooseProfilePage._enterUserSide();
    } else {
      await ChooseProfilePage._enterProfessionalSide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (_choice) {
      'professional' => 'Entrar como profissional',
      'user' => 'Entrar como usuário',
      _ => 'Escolha uma opção',
    };

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: OnboardingBackground(scene: _scene)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 14, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const OnboardingBrand(),
                      if (_canGoBack)
                        TextButton(
                          onPressed: _back,
                          style: TextButton.styleFrom(
                            foregroundColor: OnboardingColors.text,
                          ),
                          child: const Text(
                            'Voltar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                      child: AuthEntrance(from: 16, child: _card(label)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .55),
              border: Border.all(color: Colors.white.withValues(alpha: .85)),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthEntrance(
                  delay: 180,
                  child: Text(
                    _beforeLogin ? 'Você é?' : 'Como você quer entrar?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.9,
                      color: OnboardingColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuthEntrance(
                  delay: 180,
                  child: Text(
                    _beforeLogin
                        ? 'Escolha para ir direto à sua área.'
                        : 'Você pode trocar depois, no seu Perfil.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      color: OnboardingColors.body,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AuthEntrance(
                  delay: 300,
                  child: _Option(
                    icon: Icons.medical_services_outlined,
                    iconColor: const AppColor.pair(0xFF0E7F7B, 0xFF7A5FB8),
                    iconBackground: const AppColor.pair(0xFFDDF5F3, 0xFFF1E7EE),
                    title: 'Profissional',
                    subtitle: 'Sua agenda, pacientes e atendimentos',
                    selected: _choice == 'professional',
                    onTap: () => setState(() => _choice = 'professional'),
                  ),
                ),
                const SizedBox(height: 14),
                AuthEntrance(
                  delay: 420,
                  child: _Option(
                    icon: Icons.person_outline,
                    iconColor: const AppColor.pair(0xFF5B45D6, 0xFF8F72E0),
                    iconBackground: const AppColor.pair(0xFFECE8FF, 0xFFE3D8F8),
                    title: 'Usuário',
                    subtitle: 'Planos e consultas',
                    selected: _choice == 'user',
                    onTap: () => setState(() => _choice = 'user'),
                  ),
                ),
                const SizedBox(height: 26),
                AuthEntrance(
                  delay: 540,
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: OnboardingColors.text,
                          ),
                        )
                      : _EnterButton(
                          label: label,
                          onTap: _choice == null ? null : _continue,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _EnterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFFFBFAFC);
    return Opacity(
      opacity: onTap == null ? .4 : 1,
      child: Material(
        color: OnboardingColors.text,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 2,
              color: selected
                  ? OnboardingColors.text
                  : Colors.white.withValues(alpha: .9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OnboardingColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: OnboardingColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: OnboardingColors.text,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFFFBFAFC),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: OnboardingColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
