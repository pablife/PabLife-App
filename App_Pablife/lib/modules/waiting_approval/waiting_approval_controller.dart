import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/utils/app_snackbar.dart';

class WaitingApprovalController extends GetxController {
  static const String whatsappNumber = '5585999349740';
  static const String whatsappMessage =
      'Olá! Gostaria de saber sobre o status da minha aprovação como profissional.';

  Future<void> openWhatsApp() async {
    try {
      final uri = Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(whatsappMessage)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppSnackbar.to.show('Não foi possível abrir o WhatsApp');
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao abrir WhatsApp: ${e.toString()}');
    }
  }
}
