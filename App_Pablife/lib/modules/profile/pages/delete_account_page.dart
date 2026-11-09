import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/appointment_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../infra/services/subscription_service.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../profile_controller.dart';

/// "Excluir conta" (canvas S3): o que é apagado, o aviso de saldo e consultas
/// marcadas, e a confirmação digitando EXCLUIR.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  static const route = '/profile/delete-account';

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _typed = TextEditingController();
  int _balance = 0;
  int _scheduled = 0;

  bool get _ok => _typed.text.trim().toUpperCase() == 'EXCLUIR';

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    final balances = await SubscriptionService.instance
        .getConsultationBalances();
    final active = await AppointmentRepository().getPatientActiveAppointments(
      patientId: uid,
    );
    if (!mounted) return;
    setState(() {
      _balance = balances.fold(0, (s, b) => s + b.remaining);
      _scheduled = active.data?.length ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final parts = [
      if (_balance > 0)
        '$_balance ${_balance == 1 ? 'consulta' : 'consultas'} no saldo',
      if (_scheduled > 0)
        _scheduled == 1
            ? 'uma consulta marcada'
            : '$_scheduled consultas marcadas',
    ];

    Widget item(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(fontSize: 14, color: Color(0xFF2E4446)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF2E4446),
              ),
            ),
          ),
        ],
      ),
    );

    return GetBuilder<ProfileController>(
      builder: (c) => RegistrationLayout(
        title: 'Excluir conta',
        onBack: () => Get.back<void>(),
        fields: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ao excluir sua conta, isto é apagado e não dá para desfazer:',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF2E4446),
                ),
              ),
              const SizedBox(height: 8),
              item('Seus dados de cadastro e o comprovante de estudante'),
              item('Registros de humor, anotações, metas e tarefas'),
              item('Consultas que ainda estão no saldo'),
            ],
          ),
          if (parts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Você tem ${parts.join(' e ')}. Se quiser só pausar, cancele '
                'a assinatura em Minha assinatura.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF6B4A00),
                ),
              ),
            ),
          RegField(
            label: 'Para confirmar, digite EXCLUIR',
            hint: 'EXCLUIR',
            controller: _typed,
            onChanged: (_) {},
            capitalization: TextCapitalization.characters,
          ),
        ],
        footer: [
          FilledButton(
            onPressed: _ok && !c.isLoading ? controller.deleteAccount : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: PabColors.error,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFEDE4E6),
              disabledForegroundColor: const Color(0xFF8A6A70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              c.isLoading ? 'Excluindo…' : 'Excluir minha conta',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Get.back<void>(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: PabColors.ink,
              side: const BorderSide(color: PabColors.lineStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Manter minha conta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
