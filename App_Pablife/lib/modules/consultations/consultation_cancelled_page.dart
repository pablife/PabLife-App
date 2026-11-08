import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../shared/themes/pab_colors.dart';
import '../auth/pages/widgets/registration_layout.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_page.dart';
import 'consultation_info.dart';

/// "Consulta cancelada" (canvas Q6): aviso de que o horário foi liberado, se
/// a consulta voltou para o saldo, e os próximos passos.
class ConsultationCancelledPage extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;
  final bool returnedToBalance;

  const ConsultationCancelledPage({
    super.key,
    required this.appointment,
    required this.returnedToBalance,
  });

  void _goTo(int tab) {
    Get.offAllNamed(DashboardPage.route);
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return PabCardFrame(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: 'Fechar',
                  child: Material(
                    color: PabColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: PabColors.line),
                    ),
                    child: InkWell(
                      onTap: () => Get.back<void>(),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: PabColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCFD6E4),
                          width: 4,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/pages/consultations/cancelled.jpg',
                        fit: BoxFit.cover,
                        semanticLabel:
                            'Ilustração em tons apagados: moça de fone '
                            'chorando, com nuvem de chuva',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Consulta cancelada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Que pena que não deu desta vez. Avisamos '
                    '${a.professionalName.split(' ').first} e o horário de '
                    '${a.shortWhen.replaceFirst(' · ', ' às ')} foi liberado.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: PabColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PabColors.card,
                      border: Border.all(color: PabColors.line),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua consulta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          returnedToBalance
                              ? 'Voltou para o seu saldo. Você pode agendar '
                                    'outro horário quando quiser.'
                              : 'Não voltou para o saldo: o cancelamento foi '
                                    'feito com menos de 24 horas.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegPrimaryButton(
                    label: 'Agendar outro horário',
                    onTap: () => _goTo(3),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _goTo(0),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: PabColors.card,
                      foregroundColor: PabColors.ink,
                      side: const BorderSide(color: PabColors.lineStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ir para o Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
