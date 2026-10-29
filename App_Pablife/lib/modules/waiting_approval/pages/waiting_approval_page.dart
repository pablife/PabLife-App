import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/waiting_approval_controller.dart';

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  static const route = '/waiting-approval';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00343C),
      body: GetBuilder<WaitingApprovalController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const AppTextVector(width: 147, height: 45),
                const SizedBox(height: 40),
                Image.asset(
                  'assets/pages/waiting_approval/banner.png',
                  fit: BoxFit.contain,
                  width: 125,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextDefault(
                          'Aguardando',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC1CDFE).withAlpha(112),
                        ),
                        TextDefault(
                          'Aprovação',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC1CDFE).withAlpha(112),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: EdgeButtonRounded(
                    text: 'Enviar Mensagem no Whatsapp',
                    onTap: controller.openWhatsApp,
                    backgroundColor: const Color(0xFF0C8DA1),
                    side: EdgeSide.left,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }
}
