import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/professional_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../dashboard/dashboard_page.dart';
import '../../waiting_approval/pages/waiting_approval_page.dart';

/// Quem tem conta de profissional escolhe como quer entrar. É a mesma conta
/// (mesmo e-mail, CPF e senha) nos dois lados.
class ChooseProfilePage extends StatefulWidget {
  const ChooseProfilePage({super.key});

  static const route = '/choose-profile';

  @override
  State<ChooseProfilePage> createState() => _ChooseProfilePageState();
}

class _ChooseProfilePageState extends State<ChooseProfilePage> {
  bool _loading = false;

  Future<void> _enterAsUser() async {
    setState(() => _loading = true);
    await AuthService.instance.setActingAsUser(true);
    Get.offAllNamed(DashboardPage.route);
  }

  Future<void> _enterAsProfessional() async {
    setState(() => _loading = true);
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
                        const TextDefault(
                          'Como você quer entrar?',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const TextDefault(
                          'Você pode trocar depois, no seu Perfil.',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.second,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        _Option(
                          icon: Icons.medical_services_outlined,
                          title: 'Entrar como profissional',
                          subtitle: 'Sua agenda, pacientes e atendimentos',
                          onTap: _enterAsProfessional,
                        ),
                        const SizedBox(height: 12),
                        _Option(
                          icon: Icons.person_outline,
                          title: 'Entrar como usuário',
                          subtitle: 'Planner, mentorias e consultas',
                          onTap: _enterAsUser,
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
