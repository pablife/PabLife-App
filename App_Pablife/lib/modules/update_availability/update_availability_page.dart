import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/utils/app_snackbar.dart';
import '../../widgets/app_text_vector.dart';
import '../../widgets/design_system/edge_button_rounded.dart';
import '../../widgets/design_system/text_default.dart';

class UpdateAvailabilityPage extends StatelessWidget {
  const UpdateAvailabilityPage({super.key});

  String get url {
    if (Platform.isAndroid) {
      return "https://play.google.com/store/apps/details?id=com.pablife.app";
    }

    return "https://apps.apple.com/br/app/pablife-app/id6756442379";
  }

  Future<void> _openStore() async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppSnackbar.to.show('Não foi possível abrir a loja de aplicativos.');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao abrir a loja: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00343C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppTextVector(width: 147, height: 45),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextDefault(
                      'Atualização',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC1CDFE).withAlpha(112),
                    ),
                    TextDefault(
                      'Disponível',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC1CDFE).withAlpha(112),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: TextDefault(
                        'Uma nova versão do aplicativo está disponível. Atualize para continuar usando o PabLife.',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFC1CDFE).withAlpha(200),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: EdgeButtonRounded(
                text: 'Atualizar Agora',
                onTap: _openStore,
                backgroundColor: const Color(0xFF0C8DA1),
                side: EdgeSide.left,
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
