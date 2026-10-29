import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/modules/dashboard/dashboard_page.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';

class AppointmentSuccessPage extends StatelessWidget {
  const AppointmentSuccessPage({super.key});

  static const route = '/appointment-success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.second,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Imagem
            Image.asset(
              'assets/pages/onboarding/step_two.png',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 40),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const TextDefault(
                'Agendamento Realizado!',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Texto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const TextDefault(
                'Seu agendamento foi confirmado com sucesso. Você pode visualizá-lo na seção "Minhas Consultas".',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Botões
            Row(
              children: [
                Expanded(
                  child: EdgeButtonRounded(
                    text: 'Voltar ao Início',
                    onTap: () {
                      Get.offAllNamed(DashboardPage.route);
                    },
                    backgroundColor: const Color(0xFF0C8DA1),
                    side: EdgeSide.right,
                  ),
                ),
                Expanded(child: SizedBox.shrink()),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
