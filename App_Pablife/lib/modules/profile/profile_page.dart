import 'package:flutter/material.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:get/get.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/notification_button_widget.dart';
import '../../widgets/design_system/profile_avatar_widget.dart';
import '../../widgets/design_system/text_default.dart';
import 'profile_controller.dart';
import 'widgets/consultation_balance_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        if (controller.isLoading && controller.currentUser == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF00343C),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = controller.currentUser;
        if (user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF00343C),
            body: Center(
              child: Text(
                'Erro ao carregar perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          appBar: AppBarDefault(trailing: const NotificationButtonWidget()),
          body: Stack(
            children: [
              Positioned(
                top: 66,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1CDFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(39),
                      topRight: Radius.circular(39),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 95),

                      TextDefault(
                        user.fullName,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),

                      TextDefault(
                        user.email,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          children: [
                            if (controller.shouldShowConsultationCard)
                              ConsultationBalanceCard(
                                balances: controller.consultationBalances,
                                isLoading:
                                    controller.isConsultationBalancesLoading,
                                emptyMessage:
                                    'Sem consultas disponíveis no período atual.',
                              ),
                            ProfileMenuItem(
                              icon: FUI(
                                RegularRounded.WOMAN_HEAD,
                                color: AppColors.aquaIcon,
                              ),
                              title: 'Editar Perfil',
                              onTap: controller.navigateToEditProfile,
                            ),
                            const ProfileDivider(),
                            ProfileMenuItem(
                              icon: FUI(
                                RegularRounded.SETTINGS,
                                color: AppColors.aquaIcon,
                              ),
                              title: 'Minha Assinatura',
                              onTap: controller.navigateToSubscription,
                            ),
                            const ProfileDivider(),

                            ProfileMenuItem(
                              icon: const Icon(
                                Icons.logout,
                                color: AppColors.aquaIcon,
                                size: 24,
                              ),
                              title: 'Sair',
                              onTap: controller.showLogoutDialog,
                            ),
                            const ProfileDivider(),

                            ProfileMenuItem(
                              icon: FUI(
                                RegularRounded.TRASH,
                                color: AppColors.aquaIcon,
                              ),
                              title: 'Excluir Conta',
                              onTap: controller.showDeleteAccountDialog,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: ProfileAvatarWidget(
                    imageUrl: user.imageUrl,
                    onEditTap: controller.editProfilePhoto,
                    isLoading: controller.isLoading,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: SizedBox(width: 24, height: 24, child: icon),
      title: TextDefault(
        title,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black.withAlpha(143),
      ),
      trailing: FUI(
        RegularRounded.ANGLE_SMALL_RIGHT,
        width: 24,
        color: const Color(0xFF374957),
      ),
      onTap: onTap,
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.black.withAlpha(33),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
