import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../../widgets/banners/banner_carousel_widget.dart';
import '../controllers/user_home_controller.dart';
import '../widgets/home_user_header.dart';
import '../widgets/user_home_appointments_section.dart';
import '../widgets/user_home_empty_state_widget.dart';
import '../widgets/user_home_goals_section.dart';
import '../widgets/user_home_goals_progress_section.dart';
import '../widgets/user_home_professional_carousel_widget.dart';
import '../widgets/user_home_tasks_section_widget.dart';
import '../widgets/user_home_weekly_progress_widget.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  static const route = '/home/user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.aqua,
      body: GetBuilder<UserHomeController>(
        builder: (controller) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                HomeUserHeader(user: controller.user),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.second,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : controller.isEmpty
                        ? const UserHomeEmptyStateWidget()
                        : isWideLayout(context)
                        ? _WideHomeContent(controller: controller)
                        : ListView(
                            children: [
                              const SizedBox(height: 24),
                              UserHomeAppointmentsSection(
                                controller: controller,
                              ),
                              const SizedBox(height: 24),
                              UserHomeGoalsSection(controller: controller),
                              if (controller.banners.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                BannerCarouselWidget(
                                  banners: controller.banners,
                                ),
                              ],
                              if (controller.hasWeeklyProgress) ...[
                                const SizedBox(height: 24),
                                UserHomeWeeklyProgressWidget(
                                  controller: controller,
                                ),
                              ],
                              if (controller.professionals.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                UserHomeProfessionalCarouselWidget(
                                  controller: controller,
                                ),
                              ],
                              const SizedBox(height: 24),
                              UserHomeTasksSectionWidget(
                                controller: controller,
                              ),
                              const SizedBox(height: 24),
                              const UserHomeGoalsProgressSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tela inicial em telas largas: as mesmas seções, em duas colunas.
class _WideHomeContent extends StatelessWidget {
  final UserHomeController controller;
  const _WideHomeContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 24);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 14,
                  child: Column(
                    children: [
                      UserHomeAppointmentsSection(controller: controller),
                      gap,
                      UserHomeGoalsSection(controller: controller),
                      if (controller.banners.isNotEmpty) ...[
                        gap,
                        BannerCarouselWidget(banners: controller.banners),
                      ],
                      gap,
                      UserHomeTasksSectionWidget(controller: controller),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      if (controller.hasWeeklyProgress) ...[
                        UserHomeWeeklyProgressWidget(controller: controller),
                        gap,
                      ],
                      if (controller.professionals.isNotEmpty) ...[
                        UserHomeProfessionalCarouselWidget(
                          controller: controller,
                        ),
                        gap,
                      ],
                      const UserHomeGoalsProgressSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
