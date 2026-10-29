import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/professional_home_controller.dart';
import '../widgets/home_user_header.dart';
import '../../../widgets/design_system/empty_state_widget.dart';
import '../../../shared/themes/app_colors.dart';
import 'widgets/professional_home_appointment_carousel_widget.dart';
import 'widgets/professional_home_weekly_progress_widget.dart';
import 'widgets/professional_home_appointments_progress_widget.dart';
import '../../../widgets/banners/banner_carousel_widget.dart';

class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({super.key});

  static const route = '/home/professional';

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.aqua,
      body: GetBuilder<ProfessionalHomeController>(
        builder: (controller) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                HomeUserHeader(user: controller.user),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.second,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: controller.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.aqua,
                            ),
                          )
                        : controller.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: EmptyStateWidget(
                                icon: Icons.dashboard_outlined,
                                title: 'Nada por aqui ainda',
                                description:
                                    'Quando houver consultas agendadas, elas aparecerão aqui para acompanhar seu progresso.',
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 90),
                            children: [
                              const SizedBox(height: 24),
                              ProfessionalHomeAppointmentCarouselWidget(
                                controller: controller,
                              ),
                              const SizedBox(height: 24),
                              ProfessionalHomeWeeklyProgressWidget(
                                controller: controller,
                              ),
                              if (controller.banners.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                BannerCarouselWidget(
                                  banners: controller.banners,
                                ),
                              ],
                              const SizedBox(height: 24),
                              ProfessionalHomeAppointmentsProgressWidget(
                                controller: controller,
                              ),
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
