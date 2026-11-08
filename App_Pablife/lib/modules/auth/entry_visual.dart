import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/models/user_role.dart';
import '../../infra/repositories/user_preferences_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../shared/themes/app_palette.dart';
import '../../shared/themes/pab_colors.dart';
import '../women_health/pages/women_health_flow_page.dart';
import '../women_health/women_health_controller.dart';

/// O visual escolhido na entrada (tela 4b) e o que acontece com ele depois.
///
/// - Conta nova: fica com o visual escolhido. Quem escolheu a Saúde da Mulher
///   no lado usuário passa pelo questionário e pelo aceite antes de usar.
/// - Conta que já existia: entra no visual de sempre e vê, uma vez só, o
///   aviso de que a Saúde da Mulher agora pode ser escolhida no Perfil.
abstract final class EntryVisual {
  /// Resposta da tela 4b; null se a pessoa não passou por ela.
  static bool? chosenRose;

  /// Conta usuária nova que escolheu a Saúde da Mulher e ainda não respondeu
  /// o questionário: o visual rosé fica até lá.
  static bool waitingWomenFlow = false;

  static bool _newAccount = false;

  static const _noticeKey = 'women_health_notice_seen_';

  /// Chamado logo depois de criar a conta.
  static Future<void> onAccountCreated({required bool professional}) async {
    _newAccount = true;
    final rose = chosenRose;
    if (rose == null) return;
    if (rose && !professional) {
      // A trilha só começa com o questionário e o aceite.
      waitingWomenFlow = true;
      return;
    }
    await UserPreferencesRepository().saveTheme(rose: rose);
  }

  /// Chamado quando o Dashboard abre.
  static Future<void> onDashboardReady() async {
    final user = AuthService.instance.currentUser;
    if (user?.id == null || user!.role != UserRole.user) {
      _reset();
      return;
    }
    if (!Get.isRegistered<WomenHealthController>()) return;
    final women = WomenHealthController.to;
    await women.ready;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_noticeKey${user.id}';

    if (_newAccount) {
      final openFlow = waitingWomenFlow && !women.isActive;
      _reset();
      await prefs.setBool(key, true);
      if (!openFlow) return;
      await WomenHealthFlowPage.open();
      // Desistiu do questionário: volta para o visual Pablife.
      if (!women.isActive) {
        AppPalette.apply(false);
        await UserPreferencesRepository().saveTheme(rose: false);
      }
      return;
    }

    _reset();
    if (women.isActive || (prefs.getBool(key) ?? false)) return;
    await prefs.setBool(key, true);
    await _showNotice();
  }

  static void _reset() {
    _newAccount = false;
    waitingWomenFlow = false;
    chosenRose = null;
  }

  static Future<void> _showNotice() async {
    final wantsToSee = await Get.bottomSheet<bool>(
      const _WomenHealthNotice(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (wantsToSee == true) await WomenHealthFlowPage.open();
  }
}

/// Aviso único para quem já tinha conta.
class _WomenHealthNotice extends StatelessWidget {
  const _WomenHealthNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCE8F3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1D4F).withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ExcludeSemantics(
                      child: Image.asset(
                        'assets/pages/auth/login_art_rose.png',
                        height: 120,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NOVIDADE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFFD63A74),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Agora você pode usar a Pablife Saúde da Mulher',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: pabFontFamily,
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A1D4F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ciclo, gestação e menopausa, em tons de rosa e lilás. '
                    'Você troca quando quiser no Perfil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF5E4A66),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Get.back(result: true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: const Color(0xFF3A1D4F),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Conhecer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: const Color(0xFF3A1D4F),
                    ),
                    child: const Text(
                      'Agora não',
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
      ),
    );
  }
}
