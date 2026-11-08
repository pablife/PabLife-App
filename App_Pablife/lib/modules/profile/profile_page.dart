import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/repositories/student_repository.dart';
import '../../infra/repositories/user_preferences_repository.dart';
import '../../shared/themes/app_palette.dart';
import '../../shared/themes/pab_colors.dart';
import '../../widgets/design_system/profile_avatar_widget.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/pab_logo.dart';
import '../../widgets/pabi/pabi.dart';
import '../auth/pages/student_proof_page.dart';
import '../home/controllers/user_home_controller.dart';
import '../home/pages/user_home_page.dart';
import '../women_health/pages/women_health_flow_page.dart';
import '../women_health/widgets/women_health_card.dart';
import '../women_health/women_health_controller.dart';
import 'profile_controller.dart';

String _two(int value) => value.toString().padLeft(2, '0');

/// Perfil (canvas "Perfil — mobile"): foto, saldo, visual do app e menu.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        final user = controller.currentUser;
        if (user == null) {
          return Scaffold(
            backgroundColor: PabColors.background,
            body: Center(
              child: controller.isLoading
                  ? const CircularProgressIndicator(color: PabColors.accentText)
                  : const Text(
                      'Erro ao carregar perfil',
                      style: TextStyle(color: PabColors.ink),
                    ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: PabColors.background,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(controller: controller),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (controller.shouldShowConsultationCard) ...[
                          _BalanceCard(controller: controller),
                          const SizedBox(height: 12),
                        ],
                        _VisualSection(
                          professional: controller.isProfessionalView,
                        ),
                        const SizedBox(height: 12),
                        if (!controller.isProfessionalView) ...[
                          const _StudentDiscountCard(),
                          const SizedBox(height: 12),
                          const _ToolsSection(),
                          const SizedBox(height: 12),
                        ],
                        _Menu(controller: controller),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: controller.showDeleteAccountDialog,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: PabColors.error,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text(
                            'Excluir conta',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

/// "Ferramentas": o que aparece no Dashboard. Começa com o versículo do dia.
class _ToolsSection extends StatelessWidget {
  const _ToolsSection();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserHomeController>()) {
      return const SizedBox.shrink();
    }
    return GetBuilder<UserHomeController>(
      builder: (home) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        decoration: BoxDecoration(
          color: PabColors.card,
          border: Border.all(color: PabColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ferramentas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Escolha o que aparece no seu Dashboard.',
              style: TextStyle(fontSize: 13, color: PabColors.muted),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(right: 4),
              value: home.showDailyVerse,
              onChanged: home.setShowDailyVerse,
              activeThumbColor: PabColors.card,
              activeTrackColor: PabColors.accent,
              title: const Text(
                'Versículo do dia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PabColors.ink,
                ),
              ),
              subtitle: const Text(
                'Uma mensagem da Bíblia todos os dias no Dashboard.',
                style: TextStyle(fontSize: 13, color: PabColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desconto de estudante: situação do comprovante e envio pelo Perfil.
class _StudentDiscountCard extends StatefulWidget {
  const _StudentDiscountCard();

  @override
  State<_StudentDiscountCard> createState() => _StudentDiscountCardState();
}

class _StudentDiscountCardState extends State<_StudentDiscountCard> {
  late Future<StudentStatus> _status = StudentRepository().myStatus();

  Future<void> _send() async {
    await StudentProofPage.openFromProfile();
    if (mounted) setState(() => _status = StudentRepository().myStatus());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentStatus>(
      future: _status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();
        final (title, text, action) = switch (status) {
          StudentStatus.approved => (
            'Desconto de estudante ativo',
            'Você tem 10% de desconto em qualquer plano.',
            null,
          ),
          StudentStatus.pending => (
            'Comprovante em análise',
            'Respondemos em até 24 horas. Avisamos por notificação.',
            null,
          ),
          StudentStatus.rejected => (
            'Comprovante não aprovado',
            'Envie outro comprovante para ganhar 10% de desconto.',
            'Enviar de novo',
          ),
          StudentStatus.none => (
            'Sou estudante',
            'Ganhe 10% de desconto em qualquer plano.',
            'Enviar comprovante',
          ),
        };
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: status == StudentStatus.approved
                ? PabColors.soft
                : PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status == StudentStatus.approved
                      ? PabColors.card
                      : PabColors.lilac,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == StudentStatus.pending
                      ? Icons.schedule
                      : Icons.school_outlined,
                  size: 22,
                  color: status == StudentStatus.approved
                      ? PabColors.accentText
                      : PabColors.lilacText,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: PabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _send,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: PabColors.accent,
                    foregroundColor: PabColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ProfileController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;
    return Container(
      decoration: const BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  if (!isWideLayout(context)) const PabLogo(size: 22),
                  const Spacer(),
                  const PabNotificationBell(),
                ],
              ),
              ProfileAvatarWidget(
                imageUrl: user.imageUrl,
                onEditTap: controller.editProfilePhoto,
                isLoading: controller.isLoading,
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(fontSize: 14, color: PabColors.navIdle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final ProfileController controller;

  const _BalanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final balances = controller.consultationBalances;
    final total = balances.fold<int>(0, (sum, b) => sum + b.remaining);
    final expires = balances.isEmpty
        ? null
        : (balances.map((b) => b.expiresAt).toList()..sort()).first.toLocal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available,
              size: 22,
              color: PabColors.accentText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: controller.isConsultationBalancesLoading
                ? const LinearProgressIndicator(color: PabColors.accent)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == 0
                            ? 'Sem consultas disponíveis'
                            : '$total ${total == 1 ? 'consulta disponível' : 'consultas disponíveis'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      if (expires != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Válidas até ${_two(expires.day)}/'
                          '${_two(expires.month)}/${expires.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Visual do app: Pablife ou Saúde da Mulher. Entrar na Saúde da Mulher passa
/// pelo questionário e pelo consentimento; sair pede confirmação. Para o
/// profissional, muda só a figura e as cores.
class _VisualSection extends StatelessWidget {
  final bool professional;

  const _VisualSection({required this.professional});

  static void _setProfessionalVisual(bool rose) {
    AppPalette.apply(rose);
    UserPreferencesRepository().saveTheme(rose: rose);
  }

  @override
  Widget build(BuildContext context) {
    if (professional) {
      return _box(
        subtitle: 'Muda só a figura e as cores do app.',
        rose: AppPalette.isRose,
        onPablife: () => _setProfessionalVisual(false),
        onWomen: () => _setProfessionalVisual(true),
      );
    }
    if (!Get.isRegistered<WomenHealthController>()) {
      return const SizedBox.shrink();
    }
    return GetBuilder<WomenHealthController>(
      builder: (women) => _box(
        subtitle: 'Muda a figura, as cores e os conteúdos do app.',
        rose: women.isActive,
        onPablife: () => WomenHealthCard.confirmExit(context, women),
        onWomen: WomenHealthFlowPage.open,
        trail: women.trail?.title,
      ),
    );
  }

  Widget _box({
    required String subtitle,
    required bool rose,
    required VoidCallback onPablife,
    required VoidCallback onWomen,
    String? trail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Visual do app',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: PabColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VisualOption(
                  title: 'Pablife',
                  women: false,
                  inUse: !rose,
                  onTap: onPablife,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VisualOption(
                  title: 'Saúde da Mulher',
                  women: true,
                  inUse: rose,
                  onTap: onWomen,
                ),
              ),
            ],
          ),
          // A troca de trilha saiu da agenda e fica aqui.
          if (rose && trail != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trilha: $trail',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: WomenHealthFlowPage.open,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: PabColors.accentText,
                  ),
                  child: const Text(
                    'Trocar trilha',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VisualOption extends StatelessWidget {
  final String title;
  final bool women;
  final bool inUse;
  final VoidCallback onTap;

  const _VisualOption({
    required this.title,
    required this.women,
    required this.inUse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !inUse,
      selected: inUse,
      label: '$title, ${inUse ? 'em uso' : 'trocar'}',
      excludeSemantics: true,
      child: Material(
        color: inUse ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: inUse ? PabColors.accent : PabColors.lineStrong,
            width: inUse ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: inUse ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Pabi(mood: PabiMood.feliz, women: women, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      Text(
                        inUse ? 'Em uso ✓' : 'Trocar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inUse ? PabColors.accentText : PabColors.muted,
                        ),
                      ),
                    ],
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

class _Menu extends StatelessWidget {
  final ProfileController controller;

  const _Menu({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.face_outlined, 'Editar perfil', controller.navigateToEditProfile),
      (
        Icons.workspace_premium_outlined,
        'Minha assinatura',
        controller.navigateToSubscription,
      ),
      if (controller.canSwitchProfile)
        (
          Icons.swap_horiz,
          controller.switchProfileLabel,
          controller.switchProfile,
        ),
      (Icons.logout, 'Sair', controller.showLogoutDialog),
    ];

    return Container(
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, (icon, title, onTap)) in items.indexed) ...[
            if (index > 0)
              const Divider(height: 1, thickness: 1, color: PabColors.line),
            ProfileMenuItem(
              icon: Icon(icon, color: PabColors.accentText, size: 22),
              title: title,
              onTap: () => onTap(),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SizedBox(width: 24, height: 24, child: icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: PabColors.ink,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: PabColors.muted),
      onTap: onTap,
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 9, thickness: 1, color: PabColors.line);
  }
}
