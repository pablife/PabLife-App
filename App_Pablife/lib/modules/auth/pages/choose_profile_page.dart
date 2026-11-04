import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../dashboard/dashboard_page.dart';
import '../../onboarding/onboarding_page.dart';
import 'professional_profile_page.dart';
import '../../waiting_approval/pages/waiting_approval_page.dart';

/// "Você é?": primeira tela do app, antes do login. Quem tem conta de
/// profissional também passa por aqui para trocar de lado, pelo Perfil. É a
/// mesma conta (mesmo e-mail, CPF e senha) nos dois lados.
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

  bool get _beforeLogin => !AuthService.instance.isAuthenticated;

  Future<void> _choose(String choice) async {
    if (_beforeLogin) {
      AuthService.instance.entryChoice = choice;
      Get.offAllNamed(OnboardingPage.route);
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
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.second)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextDefault(
                          _beforeLogin ? 'Você é?' : 'Como você quer entrar?',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextDefault(
                          _beforeLogin
                              ? 'Escolha para ir direto à sua área.'
                              : 'Você pode trocar depois, no seu Perfil.',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.second,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        _Option(
                          icon: Icons.medical_services_outlined,
                          title: _beforeLogin
                              ? 'Profissional'
                              : 'Entrar como profissional',
                          subtitle: 'Sua agenda, pacientes e atendimentos',
                          onTap: () => _choose('professional'),
                        ),
                        const SizedBox(height: 12),
                        _Option(
                          icon: Icons.person_outline,
                          title: _beforeLogin
                              ? 'Usuário'
                              : 'Entrar como usuário',
                          subtitle: 'Planner, mentorias e consultas',
                          onTap: () => _choose('user'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.second,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30, color: AppColors.aquaText),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDefault(
                      title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aquaText,
                    ),
                    const SizedBox(height: 2),
                    TextDefault(
                      subtitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.aquaText,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.aquaText),
            ],
          ),
        ),
      ),
    );
  }
}
